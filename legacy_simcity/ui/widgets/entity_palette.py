import tkinter as tk
from typing import Callable, Optional

from core.enums import SimulationMode
from model.entity_defs import EntityRegistry


class EntityPalette(tk.Frame):
    def __init__(
        self,
        master: tk.Misc,
        registry: EntityRegistry,
        on_select_entity: Callable[[str], None],
        on_select_edge_type: Callable[[str], None],
        on_toggle_simulation: Callable[[], None],
        on_edit_json: Callable[[], None],
        on_save_game: Callable[[], None],
        on_load_game: Callable[[], None],
        width: int,
    ) -> None:
        super().__init__(master, width=width, bg="#2B2B2B")
        self.pack_propagate(False)

        self.registry = registry
        self.on_select_entity = on_select_entity
        self.on_select_edge_type = on_select_edge_type
        self.on_toggle_simulation = on_toggle_simulation
        self.on_edit_json = on_edit_json
        self.on_save_game = on_save_game
        self.on_load_game = on_load_game

        self.entity_buttons: dict[str, tk.Button] = {}
        self.edge_buttons: dict[str, tk.Button] = {}

        self.edge_counts: dict[str, int] = {}
        self.selected_edge_type: Optional[str] = None

        self.toggle_button: Optional[tk.Button] = None

        self._build_shell()
        self.rebuild()

    def _build_shell(self) -> None:
        self.catalog_title = tk.Label(
            self,
            text="BUILD MENU",
            bg="#2B2B2B",
            fg="white",
            font=("Arial", 14, "bold"),
            pady=10,
        )
        self.catalog_title.pack(fill="x")

        self.catalog_container = tk.Frame(self, bg="#2B2B2B")
        self.catalog_container.pack(fill="both", expand=True)

        self.catalog_canvas = tk.Canvas(
            self.catalog_container,
            bg="#2B2B2B",
            highlightthickness=0,
            bd=0,
        )
        self.catalog_scrollbar = tk.Scrollbar(
            self.catalog_container,
            orient="vertical",
            command=self.catalog_canvas.yview,
        )
        self.catalog_canvas.configure(yscrollcommand=self.catalog_scrollbar.set)

        self.catalog_canvas.pack(side="left", fill="both", expand=True)
        self.catalog_scrollbar.pack(side="right", fill="y")

        self.catalog_content = tk.Frame(self.catalog_canvas, bg="#2B2B2B")
        self.catalog_window = self.catalog_canvas.create_window(
            (0, 0),
            window=self.catalog_content,
            anchor="nw",
        )

        self.catalog_content.bind("<Configure>", self._on_catalog_content_configure)
        self.catalog_canvas.bind("<Configure>", self._on_catalog_canvas_configure)

        self.catalog_canvas.bind("<Enter>", self._bind_mousewheel)
        self.catalog_canvas.bind("<Leave>", self._unbind_mousewheel)

        self.bottom_panel = tk.Frame(self, bg="#2B2B2B")
        self.bottom_panel.pack(fill="x", side="bottom")


        json_btn = tk.Button(
            self.bottom_panel,
            text="EDIT WORLD",
            font=("Arial", 12, "bold"),
            bg="#444488",
            fg="white",
            activebackground="#5555AA",
            activeforeground="white",
            relief="flat",
            command=self.on_edit_json,
        )
        json_btn.pack(fill="x", padx=12, pady=6, ipady=10)

        save_btn = tk.Button(
            self.bottom_panel,
            text="SAVE",
            font=("Arial", 12, "bold"),
            bg="#3A6EA5",
            fg="white",
            activebackground="#4B82BF",
            activeforeground="white",
            relief="flat",
            command=self.on_save_game,
        )
        save_btn.pack(fill="x", padx=12, pady=6, ipady=10)

        load_btn = tk.Button(
            self.bottom_panel,
            text="LOAD",
            font=("Arial", 12, "bold"),
            bg="#6C5A9A",
            fg="white",
            activebackground="#806DB0",
            activeforeground="white",
            relief="flat",
            command=self.on_load_game,
        )
        load_btn.pack(fill="x", padx=12, pady=6, ipady=10)

        self.toggle_button = tk.Button(
            self.bottom_panel,
            text="▶ PLAY",
            font=("Arial", 12, "bold"),
            bg="#1F6F3E",
            fg="white",
            activebackground="#2B8E50",
            activeforeground="white",
            relief="flat",
            command=self.on_toggle_simulation,
        )
        self.toggle_button.pack(fill="x", padx=12, pady=12, ipady=12)

    def set_entity_unlock_states(self, unlock_states: dict[str, tuple[bool, list[str]]]) -> None:
        for entity_id, btn in self.entity_buttons.items():
            unlocked, _missing = unlock_states.get(entity_id, (True, []))

            if unlocked:
                btn.config(
                    bg="#3A3A3A",
                    fg="white",
                    activebackground="#555555",
                    activeforeground="white",
                )
            else:
                btn.config(
                    bg="#1F1F1F",
                    fg="#777777",
                    activebackground="#2A2A2A",
                    activeforeground="#AAAAAA",
                )

    def _restyle_edge_button(self, edge_type_id: str) -> None:
        btn = self.edge_buttons.get(edge_type_id)
        if btn is None:
            return

        count = self.edge_counts.get(edge_type_id, 0)
        selected = edge_type_id == self.selected_edge_type

        if count <= 0:
            btn.config(
                bg="#1F1F1F",
                fg="#777777",
                activebackground="#2A2A2A",
                activeforeground="#AAAAAA",
            )
        elif selected:
            btn.config(
                bg="#006666",
                fg="white",
                activebackground="#008888",
                activeforeground="white",
            )
        else:
            btn.config(
                bg="#3A3A3A",
                fg="white",
                activebackground="#555555",
                activeforeground="white",
            )

    def set_transport_inventory_counts(self, counts: dict[str, int]) -> None:
        self.edge_counts = dict(counts)

        for edge_type_id, btn in self.edge_buttons.items():
            edge_def = self.registry.get_edge_type(edge_type_id)
            mode_text = "↔" if edge_def.mode == "ping_pong" else "→"
            count = self.edge_counts.get(edge_type_id, 0)

            btn.config(
                text=f"{edge_def.label} {mode_text}  x{count}  ({edge_def.speed:g}/{edge_def.capacity_per_trip:g})"
            )
            self._restyle_edge_button(edge_type_id)

    def _on_catalog_content_configure(self, _event) -> None:
        self.catalog_canvas.configure(scrollregion=self.catalog_canvas.bbox("all"))

    def _on_catalog_canvas_configure(self, event) -> None:
        self.catalog_canvas.itemconfigure(self.catalog_window, width=event.width)

    def _bind_mousewheel(self, _event=None) -> None:
        self.catalog_canvas.bind_all("<MouseWheel>", self._on_mousewheel_windows)
        self.catalog_canvas.bind_all("<Button-4>", self._on_mousewheel_linux_up)
        self.catalog_canvas.bind_all("<Button-5>", self._on_mousewheel_linux_down)

    def _unbind_mousewheel(self, _event=None) -> None:
        self.catalog_canvas.unbind_all("<MouseWheel>")
        self.catalog_canvas.unbind_all("<Button-4>")
        self.catalog_canvas.unbind_all("<Button-5>")

    def _on_mousewheel_windows(self, event) -> None:
        self.catalog_canvas.yview_scroll(int(-event.delta / 120), "units")

    def _on_mousewheel_linux_up(self, _event) -> None:
        self.catalog_canvas.yview_scroll(-1, "units")

    def _on_mousewheel_linux_down(self, _event) -> None:
        self.catalog_canvas.yview_scroll(1, "units")

    def rebuild(self) -> None:
        for child in self.catalog_content.winfo_children():
            child.destroy()

        self.entity_buttons = {}
        self.edge_buttons = {}

        entity_title = tk.Label(
            self.catalog_content,
            text="ENTITIES",
            bg="#2B2B2B",
            fg="#00AAFF",
            font=("Arial", 13, "bold"),
            pady=10,
        )
        entity_title.pack(fill="x")

        for entity_id in self.registry.get_all_ids():
            btn = tk.Button(
                self.catalog_content,
                text=entity_id,
                font=("Arial", 11, "bold"),
                bg="#3A3A3A",
                fg="white",
                activebackground="#555555",
                activeforeground="white",
                relief="flat",
                command=lambda e=entity_id: self.on_select_entity(e),
            )
            btn.pack(fill="x", padx=12, pady=4, ipady=8)
            self.entity_buttons[entity_id] = btn

        edge_title = tk.Label(
            self.catalog_content,
            text="TRANSPORT",
            bg="#2B2B2B",
            fg="#00AAFF",
            font=("Arial", 13, "bold"),
            pady=10,
        )
        edge_title.pack(fill="x", pady=(10, 0))

        for edge_type_id in self.registry.get_all_edge_type_ids():
            edge_def = self.registry.get_edge_type(edge_type_id)
            mode_text = "↔" if edge_def.mode == "ping_pong" else "→"
            count = self.edge_counts.get(edge_type_id, 0)

            btn = tk.Button(
                self.catalog_content,
                text=f"{edge_def.label} {mode_text}  x{count}  ({edge_def.speed:g}/{edge_def.capacity_per_trip:g})",
                font=("Arial", 10, "bold"),
                bg="#3A3A3A",
                fg="white",
                activebackground="#555555",
                activeforeground="white",
                relief="flat",
                command=lambda e=edge_type_id: self.on_select_edge_type(e),
            )
            btn.pack(fill="x", padx=12, pady=4, ipady=8)
            self.edge_buttons[edge_type_id] = btn
            self._restyle_edge_button(edge_type_id)

        self.catalog_canvas.update_idletasks()
        self.catalog_canvas.configure(scrollregion=self.catalog_canvas.bbox("all"))

    def set_selected_entity(self, selected: Optional[str]) -> None:
        for entity_id, btn in self.entity_buttons.items():
            if entity_id == selected:
                btn.config(bg="#777700", fg="white")
            else:
                btn.config(bg="#3A3A3A")

    def set_selected_edge_type(self, selected: Optional[str]) -> None:
        self.selected_edge_type = selected
        for edge_type_id in self.edge_buttons.keys():
            self._restyle_edge_button(edge_type_id)

    def set_simulation_mode(self, mode: SimulationMode) -> None:
        if self.toggle_button is None:
            return

        if mode == SimulationMode.PAUSED:
            self.toggle_button.config(
                text="▶ PLAY",
                bg="#1F6F3E",
                activebackground="#2B8E50",
            )
        else:
            self.toggle_button.config(
                text="⏸ PAUSE",
                bg="#7A2E2E",
                activebackground="#9A3C3C",
            )