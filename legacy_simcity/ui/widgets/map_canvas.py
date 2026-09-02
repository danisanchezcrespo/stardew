import math
import time
import tkinter as tk

from core.constants import ENTITY_RADIUS, GRID_SPACING
from core.enums import NodeState
from editor.app_controller import AppController


class MapCanvas(tk.Canvas):
    def __init__(self, master: tk.Misc, controller: AppController) -> None:
        super().__init__(master, bg="#171717", highlightthickness=0)
        self.controller = controller

        self._fps_last_t = time.perf_counter()
        self._fps_frames = 0
        self._fps_value = 0.0

        self._background_id: int | None = None
        self._fps_text_id: int | None = None
        self._notification_text_id: int | None = None

        self._grid_item_ids: list[int] = []
        self._grid_cache_key: tuple[int, int, int, int, int] | None = None

        self._node_items: dict[int, dict[str, int | None]] = {}
        self._edge_items: dict[tuple[int, int], dict[str, int | None]] = {}

        self._bind_events()

    def _bind_events(self) -> None:
        self.bind("<Button-1>", self._on_left_press)
        self.bind("<B1-Motion>", self._on_left_drag)
        self.bind("<ButtonRelease-1>", self._on_left_release)
        self.bind("<Button-3>", self._on_right_click)
        self.bind("<MouseWheel>", self._on_mousewheel)
        self.bind("<Button-4>", self._on_mousewheel_linux_up)
        self.bind("<Button-5>", self._on_mousewheel_linux_down)

    def _find_edge_at(self, sx: float, sy: float) -> int | None:
        threshold = 8.0  # pixels

        for i, edge in enumerate(self.controller.project.graph.edges):
            from_node = self.controller.project.graph.get_node(edge.from_id)
            to_node = self.controller.project.graph.get_node(edge.to_id)
            if from_node is None or to_node is None:
                continue

            ax, ay = self.controller.world_to_screen(from_node.world_x, from_node.world_y)
            bx, by = self.controller.world_to_screen(to_node.world_x, to_node.world_y)

            # Distance from point to segment
            dx = bx - ax
            dy = by - ay
            length_sq = dx * dx + dy * dy
            if length_sq == 0:
                continue

            t = ((sx - ax) * dx + (sy - ay) * dy) / length_sq
            t = max(0.0, min(1.0, t))

            px = ax + t * dx
            py = ay + t * dy

            dist = math.hypot(sx - px, sy - py)

            if dist <= threshold:
                return i

        return None


    def _on_left_press(self, event) -> None:
        # 1) Try selecting an edge first
        edge_index = self._find_edge_at(event.x, event.y)
        if edge_index is not None:
            self.controller.state.selected_edge_index = edge_index
            self.controller.state.selected_node_id = None
            self.redraw()
            return

        # Remember previous selection
        previous_node_id = self.controller.state.selected_node_id
        previous_edge_index = self.controller.state.selected_edge_index

        # Let controller handle normal left-click logic
        self.controller.begin_left_press(event.x, event.y)

        # If nothing changed, assume empty-space click and clear selection
        if (
            self.controller.state.selected_node_id == previous_node_id
            and self.controller.state.selected_edge_index == previous_edge_index
        ):
            self.controller.state.selected_node_id = None
            self.controller.state.selected_edge_index = None

        self.redraw()
        
    def _on_left_drag(self, event) -> None:
        self.controller.update_left_drag(event.x, event.y)
        self.redraw()

    def _on_left_release(self, event) -> None:
        self.controller.end_left_release(event.x, event.y)
        self.redraw()

    def _on_right_click(self, event) -> None:
        self.controller.handle_right_click(event.x, event.y)
        self.redraw()

    def _on_mousewheel(self, event) -> None:
        self.controller.zoom_at_screen_point(event.x, event.y, zoom_in=(event.delta > 0))
        self.redraw()

    def _on_mousewheel_linux_up(self, event) -> None:
        self.controller.zoom_at_screen_point(event.x, event.y, zoom_in=True)
        self.redraw()

    def _on_mousewheel_linux_down(self, event) -> None:
        self.controller.zoom_at_screen_point(event.x, event.y, zoom_in=False)
        self.redraw()

    def redraw(self) -> None:
        width = max(1, self.winfo_width())
        height = max(1, self.winfo_height())

        self._ensure_background(width, height)
        self._update_grid(width, height)
        self._update_edges()
        self._update_nodes()
        self._update_notification()
        self._update_and_draw_fps()

        self._raise_layers()

    def _raise_layers(self) -> None:
        self.tag_raise("grid")
        self.tag_raise("edge")
        self.tag_raise("edge_label")
        self.tag_raise("packet")
        self.tag_raise("node_ring")
        self.tag_raise("node_body")
        self.tag_raise("node_arc")
        self.tag_raise("node_label")
        self.tag_raise("overlay")

    def _ensure_background(self, width: int, height: int) -> None:
        if self._background_id is None:
            self._background_id = self.create_rectangle(
                0,
                0,
                width,
                height,
                fill="#171717",
                outline="",
                tags=("background",),
            )
        else:
            self.coords(self._background_id, 0, 0, width, height)

    def _update_and_draw_fps(self) -> None:
        now = time.perf_counter()
        self._fps_frames += 1

        elapsed = now - self._fps_last_t
        if elapsed >= 0.5:
            self._fps_value = self._fps_frames / elapsed
            self._fps_frames = 0
            self._fps_last_t = now

        text = f"FPS: {self._fps_value:0.1f}"

        if self._fps_text_id is None:
            self._fps_text_id = self.create_text(
                20,
                20,
                anchor="nw",
                text=text,
                fill="white",
                font=("Arial", 20, "bold"),
                tags=("overlay",),
            )
        else:
            self.coords(self._fps_text_id, 20, 20)
            self.itemconfig(self._fps_text_id, text=text)

    def _grid_key(self, width: int, height: int) -> tuple[int, int, int, int, int]:
        return (
            width,
            height,
            int(round(self.controller.state.scale * 1000)),
            int(round(self.controller.state.pan_x)),
            int(round(self.controller.state.pan_y)),
        )

    def _clear_grid(self) -> None:
        for item_id in self._grid_item_ids:
            self.delete(item_id)
        self._grid_item_ids.clear()

    def _update_grid(self, width: int, height: int) -> None:
        key = self._grid_key(width, height)
        if key == self._grid_cache_key:
            return

        self._grid_cache_key = key
        self._clear_grid()

        spacing = GRID_SPACING * self.controller.state.scale
        if spacing < 20:
            return

        start_x = self.controller.state.pan_x % spacing
        x = start_x
        while x < width:
            item_id = self.create_line(x, 0, x, height, fill="#242424", width=1, tags=("grid",))
            self._grid_item_ids.append(item_id)
            x += spacing

        start_y = self.controller.state.pan_y % spacing
        y = start_y
        while y < height:
            item_id = self.create_line(0, y, width, y, fill="#242424", width=1, tags=("grid",))
            self._grid_item_ids.append(item_id)
            y += spacing

    def _packet_radius(self, amount: float) -> float:
        return max(4.0, 1.5 + 1.2 * math.sqrt(max(0.0, amount)))

    def _arrowhead_points(
        self,
        ax: float,
        ay: float,
        bx: float,
        by: float,
        line_width: int,
    ) -> tuple[float, float, float, float, float, float] | None:
        dx = bx - ax
        dy = by - ay
        length = math.hypot(dx, dy)
        if length <= 0.001:
            return None

        ux = dx / length
        uy = dy / length

        head_len = max(10, line_width * 3)
        head_w = max(7, line_width * 2)

        base_x = bx - ux * head_len
        base_y = by - uy * head_len

        px = -uy
        py = ux

        p1 = (bx, by)
        p2 = (base_x + px * head_w * 0.5, base_y + py * head_w * 0.5)
        p3 = (base_x - px * head_w * 0.5, base_y - py * head_w * 0.5)

        return (p1[0], p1[1], p2[0], p2[1], p3[0], p3[1])

    def _line_bbox_intersects_screen(
        self,
        ax: float,
        ay: float,
        bx: float,
        by: float,
        pad: float = 50.0,
    ) -> bool:
        width = self.winfo_width()
        height = self.winfo_height()

        min_x = min(ax, bx) - pad
        max_x = max(ax, bx) + pad
        min_y = min(ay, by) - pad
        max_y = max(ay, by) + pad

        return not (
            max_x < 0 or
            max_y < 0 or
            min_x > width or
            min_y > height
        )

    def _edge_key(self, from_id: int, to_id: int) -> tuple[int, int]:
        return (from_id, to_id)

    def _ensure_edge_items(self, edge_key: tuple[int, int]) -> dict[str, int | None]:
        items = self._edge_items.get(edge_key)
        if items is None:
            items = {
                "line": None,
                "arrow": None,
                "label": None,
                "packet": None,
                "return_packet": None,
            }
            self._edge_items[edge_key] = items
        return items

    def _hide_edge_items(self, items: dict[str, int | None]) -> None:
        for item_id in items.values():
            if item_id is not None:
                self.itemconfigure(item_id, state="hidden")

    def _delete_edge_items(self, edge_key: tuple[int, int]) -> None:
        items = self._edge_items.pop(edge_key, None)
        if items is None:
            return
        for item_id in items.values():
            if item_id is not None:
                self.delete(item_id)

    def _update_edges(self) -> None:
        selected_edge_index = self.controller.state.selected_edge_index
        active_keys: set[tuple[int, int]] = set()

        for i, edge in enumerate(self.controller.project.graph.edges):
            from_node = self.controller.project.graph.get_node(edge.from_id)
            to_node = self.controller.project.graph.get_node(edge.to_id)
            if from_node is None or to_node is None:
                continue

            edge_key = self._edge_key(edge.from_id, edge.to_id)
            active_keys.add(edge_key)
            items = self._ensure_edge_items(edge_key)

            ax, ay = self.controller.world_to_screen(from_node.world_x, from_node.world_y)
            bx, by = self.controller.world_to_screen(to_node.world_x, to_node.world_y)

            if not self._line_bbox_intersects_screen(ax, ay, bx, by):
                self._hide_edge_items(items)
                continue

            edge_def = self.controller.registry.get_edge_type(edge.edge_type_id)
            is_selected = i == selected_edge_index

            line_color = "#FFFFFF" if is_selected else edge_def.color
            line_width = 5 if is_selected else 3

            if items["line"] is None:
                items["line"] = self.create_line(
                    ax,
                    ay,
                    bx,
                    by,
                    fill=line_color,
                    width=line_width,
                    tags=("edge",),
                )
            else:
                self.coords(items["line"], ax, ay, bx, by)
                self.itemconfig(items["line"], fill=line_color, width=line_width, state="normal")

            arrow_points = self._arrowhead_points(ax, ay, bx, by, line_width)
            if arrow_points is not None:
                if items["arrow"] is None:
                    items["arrow"] = self.create_polygon(
                        *arrow_points,
                        fill=line_color,
                        outline=line_color,
                        tags=("edge",),
                    )
                else:
                    self.coords(items["arrow"], *arrow_points)
                    self.itemconfig(items["arrow"], fill=line_color, outline=line_color, state="normal")

            mode_suffix = "↔" if edge_def.mode == "ping_pong" else "→"
            mx = (ax + bx) * 0.5
            my = (ay + by) * 0.5
            label_text = f"{edge_def.label} {mode_suffix}"

            if items["label"] is None:
                items["label"] = self.create_text(
                    mx,
                    my - 12,
                    text=label_text,
                    fill=edge_def.color,
                    font=("Arial", 11, "bold"),
                    anchor="center",
                    tags=("edge_label",),
                )
            else:
                self.coords(items["label"], mx, my - 12)
                self.itemconfig(items["label"], text=label_text, fill=edge_def.color, state="normal")

            if edge.packet is not None:
                px = ax + (bx - ax) * edge.packet.progress
                py = ay + (by - ay) * edge.packet.progress
                r = self._packet_radius(edge.packet.amount)

                if items["packet"] is None:
                    items["packet"] = self.create_oval(
                        px - r,
                        py - r,
                        px + r,
                        py + r,
                        fill=edge_def.color,
                        outline="white",
                        width=1,
                        tags=("packet",),
                    )
                else:
                    self.coords(items["packet"], px - r, py - r, px + r, py + r)
                    self.itemconfig(items["packet"], fill=edge_def.color, outline="white", state="normal")
            elif items["packet"] is not None:
                self.itemconfig(items["packet"], state="hidden")

            if edge.return_progress is not None:
                rx = bx + (ax - bx) * edge.return_progress
                ry = by + (ay - by) * edge.return_progress
                r = 4

                if items["return_packet"] is None:
                    items["return_packet"] = self.create_oval(
                        rx - r,
                        ry - r,
                        rx + r,
                        ry + r,
                        outline=edge_def.color,
                        width=2,
                        tags=("packet",),
                    )
                else:
                    self.coords(items["return_packet"], rx - r, ry - r, rx + r, ry + r)
                    self.itemconfig(items["return_packet"], outline=edge_def.color, state="normal")
            elif items["return_packet"] is not None:
                self.itemconfig(items["return_packet"], state="hidden")

        stale_keys = [key for key in self._edge_items.keys() if key not in active_keys]
        for key in stale_keys:
            self._delete_edge_items(key)

    def _node_is_on_screen(self, sx: float, sy: float, pad: float) -> bool:
        width = self.winfo_width()
        height = self.winfo_height()
        return not (
            sx < -pad or
            sy < -pad or
            sx > width + pad or
            sy > height + pad
        )

    def _build_node_label(self, node_id: int) -> str:
        node = self.controller.project.graph.get_node(node_id)
        if node is None:
            return "?"

        entity_def = self.controller.registry.get(node.entity_type)

        if node.state == NodeState.UNDER_CONSTRUCTION:
            status = "BUILDING"
        elif node.state == NodeState.RUNNING:
            status = "WORKING"
        elif node.state == NodeState.READY:
            status = "STOPPED"
        else:
            status = str(node.state).split(".")[-1]

        return f"{entity_def.label}\n{status}"

    def _ensure_node_items(self, node_id: int) -> dict[str, int | None]:
        items = self._node_items.get(node_id)
        if items is None:
            items = {
                "body": None,
                "ring": None,
                "arc": None,
                "label": None,
            }
            self._node_items[node_id] = items
        return items

    def _hide_node_items(self, items: dict[str, int | None]) -> None:
        for item_id in items.values():
            if item_id is not None:
                self.itemconfigure(item_id, state="hidden")

    def _delete_node_items(self, node_id: int) -> None:
        items = self._node_items.pop(node_id, None)
        if items is None:
            return
        for item_id in items.values():
            if item_id is not None:
                self.delete(item_id)

    def _update_nodes(self) -> None:
        radius = max(12, ENTITY_RADIUS * self.controller.state.scale)
        cell_size = int(GRID_SPACING * self.controller.state.scale)

        active_node_ids: set[int] = set()

        for node in self.controller.project.graph.nodes.values():
            active_node_ids.add(node.id)
            items = self._ensure_node_items(node.id)

            sx, sy = self.controller.world_to_screen(node.world_x, node.world_y)

            if not self._node_is_on_screen(sx, sy, pad=max(radius, cell_size * 0.5) + 32):
                self._hide_node_items(items)
                continue

            entity_def = self.controller.registry.get(node.entity_type)
            selected = node.id == self.controller.state.selected_node_id

            if node.state == NodeState.UNDER_CONSTRUCTION:
                fill_color = "#555555"
                outline = "#FFFFFF" if selected else "#BBBBBB"
            elif node.state == NodeState.RUNNING:
                fill_color = entity_def.color
                outline = "#FFFFFF" if selected else "#111111"
            elif node.state == NodeState.READY:
                fill_color = entity_def.color
                outline = "#FFFFFF" if selected else "#222222"
            else:
                fill_color = entity_def.color
                outline = "#FFFFFF" if selected else "#111111"

            body_width = 3 if selected else 2

            if items["body"] is None:
                items["body"] = self.create_oval(
                    sx - radius,
                    sy - radius,
                    sx + radius,
                    sy + radius,
                    fill=fill_color,
                    outline=outline,
                    width=body_width,
                    tags=("node_body",),
                )
            else:
                self.coords(items["body"], sx - radius, sy - radius, sx + radius, sy + radius)
                self.itemconfig(items["body"], fill=fill_color, outline=outline, width=body_width, state="normal")

            ring_radius = max(radius, cell_size * 0.48)
            ring_width = 3 if selected else 2

            if items["ring"] is None:
                items["ring"] = self.create_oval(
                    sx - ring_radius,
                    sy - ring_radius,
                    sx + ring_radius,
                    sy + ring_radius,
                    outline=outline,
                    width=ring_width,
                    tags=("node_ring",),
                )
            else:
                self.coords(items["ring"], sx - ring_radius, sy - ring_radius, sx + ring_radius, sy + ring_radius)
                self.itemconfig(items["ring"], outline=outline, width=ring_width, state="normal")

            progress = None
            if node.state == NodeState.UNDER_CONSTRUCTION:
                progress = self.controller.get_node_construction_progress(node.id)
            elif node.state == NodeState.RUNNING and node.active_process_total_sec > 0:
                progress = 1.0 - (node.active_process_remaining_sec / node.active_process_total_sec)

            if progress is not None:
                extent = max(0.0, min(359.9, progress * 360.0))
                arc_radius = max(radius, cell_size * 0.40)

                if items["arc"] is None:
                    items["arc"] = self.create_arc(
                        sx - arc_radius - 5,
                        sy - arc_radius - 5,
                        sx + arc_radius + 5,
                        sy + arc_radius + 5,
                        start=90,
                        extent=-extent,
                        style=tk.ARC,
                        outline="#FFD966",
                        width=3,
                        tags=("node_arc",),
                    )
                else:
                    self.coords(
                        items["arc"],
                        sx - arc_radius - 5,
                        sy - arc_radius - 5,
                        sx + arc_radius + 5,
                        sy + arc_radius + 5,
                    )
                    self.itemconfig(items["arc"], start=90, extent=-extent, outline="#FFD966", state="normal")
            elif items["arc"] is not None:
                self.itemconfig(items["arc"], state="hidden")

            label_text = self._build_node_label(node.id)
            if items["label"] is None:
                items["label"] = self.create_text(
                    sx,
                    sy,
                    text=label_text,
                    fill="white",
                    font=("Arial", 10, "bold"),
                    justify="center",
                    anchor="center",
                    tags=("node_label",),
                )
            else:
                self.coords(items["label"], sx, sy)
                self.itemconfig(items["label"], text=label_text, fill="white", state="normal")
            
        stale_node_ids = [node_id for node_id in self._node_items.keys() if node_id not in active_node_ids]
        for node_id in stale_node_ids:
            self._delete_node_items(node_id)

    def _update_notification(self) -> None:
        text = self.controller.state.notification_text

        if not text:
            if self._notification_text_id is not None:
                self.itemconfig(self._notification_text_id, state="hidden")
            return

        if self._notification_text_id is None:
            self._notification_text_id = self.create_text(
                600,
                20,
                text=text,
                fill="#FFD966",
                font=("Arial", 16, "bold"),
                anchor="nw",
                tags=("overlay",),
            )
        else:
            self.coords(self._notification_text_id, 600, 20)
            self.itemconfig(self._notification_text_id, text=text, state="normal")