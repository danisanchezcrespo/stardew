import tkinter as tk

from persistence.savegame_io import save_game_to_path, load_game_from_path
from tkinter import filedialog
from core.constants import SIDEBAR_WIDTH, SIMULATION_INTERVAL_MS
from editor.app_controller import AppController
from ui.widgets.entity_palette import EntityPalette
from ui.widgets.json_editor_dialog import JsonEditorDialog
from ui.widgets.map_canvas import MapCanvas
from ui.widgets.world_status_panel import WorldStatusPanel
from ui.widgets.node_info_panel import NodeInfoPanel
import time


class AppWindow:
    RIGHT_PANEL_WIDTH = 300

    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.controller = AppController()

        self.root.title("Graph Strategy Interpreter")
        self.root.attributes("-fullscreen", True)
        self.root.configure(bg="#202020")

        self._build_ui()
        self._bind_events()
        self._last_sim_time = time.perf_counter()
        self._refresh_ui()
        self._schedule_simulation_tick()
        self._schedule_render_tick()
        self._schedule_panel_tick()

    def _schedule_render_tick(self) -> None:
        self.root.after(5, self._on_render_tick)

    def _on_render_tick(self) -> None:
        self.canvas.redraw()
        self._schedule_render_tick()

    def _schedule_panel_tick(self) -> None:
        self.root.after(250, self._on_panel_tick)

    def _on_panel_tick(self) -> None:
        self._refresh_non_canvas_ui()
        self._schedule_panel_tick()

    def _refresh_non_canvas_ui(self) -> None:
        self._refresh_palette()
        self._refresh_world_status_panel()
        self._refresh_node_info_panel()

    def _refresh_palette(self) -> None:
        self.palette.set_entity_unlock_states(
            self.controller.get_entity_unlock_states()
        )

        self.palette.set_transport_inventory_counts(
            self.controller.get_transport_inventory_counts()
        )

        self.palette.set_selected_entity(self.controller.state.selected_palette_entity)
        self.palette.set_selected_edge_type(self.controller.state.selected_edge_type)
        self.palette.set_simulation_mode(self.controller.state.simulation_mode)

    def _build_ui(self) -> None:
        self.palette = EntityPalette(
            self.root,
            registry=self.controller.registry,
            on_select_entity=self._on_select_entity,
            on_select_edge_type=self._on_select_edge_type,
            on_toggle_simulation=self._on_toggle_simulation,
            on_edit_json=self._on_edit_json,
            on_save_game=self._save_game,
            on_load_game=self._load_game,
            width=SIDEBAR_WIDTH,
        )
        self.palette.pack(side="left", fill="y")

        self.canvas = MapCanvas(self.root, self.controller)
        self.canvas.pack(side="left", fill="both", expand=True)

        self.right_panel = tk.Frame(
            self.root,
            bg="#202020",
            width=self.RIGHT_PANEL_WIDTH,
        )
        self.right_panel.pack(side="right", fill="y")
        self.right_panel.pack_propagate(False)

        self.world_status_panel = WorldStatusPanel(self.right_panel)
        self.world_status_panel.pack(fill="x", padx=8, pady=(8, 6))

        # ✅ Updated: no on_toggle_ready anymore
        self.node_info_panel = NodeInfoPanel(self.right_panel)
        self.node_info_panel.pack(fill="both", expand=True, padx=8, pady=(6, 8))

    def _save_game(self):
        path = filedialog.asksaveasfilename(
            defaultextension=".json",
            filetypes=[("Savegame", "*.json")],
        )
        if not path:
            return

        save_game_to_path(self.controller.project, self.controller.state, path)

    def _load_game(self):
        path = filedialog.askopenfilename(
            filetypes=[("Savegame", "*.json")],
        )
        if not path:
            return

        load_game_from_path(self.controller.project, self.controller.state, path)
        self._refresh_ui()

    def _bind_events(self) -> None:
        self.root.bind("<Escape>", self._on_escape)
        self.root.bind("<Delete>", self._on_delete_key)
        self.root.bind("<BackSpace>", self._on_delete_key)

    def _on_escape(self, _event) -> None:
        self.root.attributes("-fullscreen", False)

    def _on_delete_key(self, _event) -> None:
        self.controller.delete_selected()
        self._refresh_ui()

    def _on_select_entity(self, entity_type: str) -> None:
        self.controller.select_palette_entity(entity_type)
        self._refresh_ui()

    def _on_select_edge_type(self, edge_type_id: str) -> None:
        self.controller.select_edge_type(edge_type_id)
        self._refresh_ui()

    def _on_toggle_simulation(self) -> None:
        self.controller.toggle_simulation_mode()
        self._refresh_ui()

    def _on_edit_json(self) -> None:
        json_data = self.controller.get_current_json_data()
        JsonEditorDialog(self.root, json_data, self._on_json_saved)

    def _on_json_saved(self, updated_json) -> None:
        self.controller.set_current_json_data(updated_json)
        self.controller.reload_from_json()

        self.palette.registry = self.controller.registry
        self.palette.rebuild()
        self._refresh_ui()

    def _refresh_ui(self) -> None:
        self._refresh_non_canvas_ui()
        self.canvas.redraw()

    def _refresh_world_status_panel(self) -> None:
        world = self.controller.get_world_status()

        self.world_status_panel.update_status(
            building_count=world["building_count"],
            resident_count=world["resident_count"],
            unemployment_percent=world["unemployment_percent"],
            food_reserves=world["food_reserves"],
            growth_text=world["growth_text"],
        )

    def _refresh_node_info_panel(self) -> None:
        info = self.controller.get_selected_node_info()
        if info is None:
            self.node_info_panel.clear()
            return

        state_text = str(info["state"]).lower()

        if "construction" in state_text:
            rows = info.get("construction_materials", [])
            contents_text = "\n".join(
                f"- {row['resource']}: {row['have']:g} / {row['need']:g}"
                for row in rows
            ) or "-"
        else:
            contents = info["contents"]
            contents_text = "\n".join(
                f"- {name}: {amount:g}" for name, amount in contents.items()
            ) or "-"

        self.node_info_panel.update_node_info(
            node_name=info["node_name"],
            recipe_name=info["recipe_name"],
            contents_text=contents_text,
            workers_assigned=info["workers_assigned"],
            workers_total=info["workers_total"],
            node_state=str(info["state"]),
        )

    def _schedule_simulation_tick(self) -> None:
        self.root.after(SIMULATION_INTERVAL_MS, self._on_simulation_tick)

    def _on_simulation_tick(self) -> None:
        now = time.perf_counter()
        dt = now - self._last_sim_time
        self._last_sim_time = now

        if self.controller.is_running():
            dt = min(dt, 0.2)
            self.controller.simulation_step(dt)

        self._schedule_simulation_tick()

    def run(self) -> None:
        self.canvas.redraw()
        self.root.mainloop()