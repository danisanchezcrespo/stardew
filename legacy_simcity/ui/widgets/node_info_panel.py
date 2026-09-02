import tkinter as tk
from typing import Optional


class NodeInfoPanel(tk.Frame):
    def __init__(self, master) -> None:
        super().__init__(master, bg="#2a2a2a", bd=1, relief="solid")

        self.selected_node_id: Optional[str] = None

        self.title_var = tk.StringVar(value="Selected Node")
        self.status_var = tk.StringVar(value="Status: -")
        self.recipe_var = tk.StringVar(value="Recipe: -")
        self.contents_var = tk.StringVar(value="Contents: -")
        self.workers_var = tk.StringVar(value="Workers: -")

        tk.Label(
            self,
            textvariable=self.title_var,
            bg="#2a2a2a",
            fg="white",
            font=("Arial", 11, "bold"),
            anchor="w",
        ).pack(fill="x", padx=8, pady=(6, 4))

        tk.Label(
            self,
            textvariable=self.status_var,
            bg="#2a2a2a",
            fg="#FFD966",
            anchor="w",
        ).pack(fill="x", padx=8, pady=(0, 4))

        tk.Label(
            self,
            textvariable=self.recipe_var,
            bg="#2a2a2a",
            fg="#dddddd",
            justify="left",
            anchor="w",
        ).pack(fill="x", padx=8, pady=2)

        tk.Label(
            self,
            textvariable=self.contents_var,
            bg="#2a2a2a",
            fg="#dddddd",
            justify="left",
            anchor="w",
        ).pack(fill="x", padx=8, pady=2)

        tk.Label(
            self,
            textvariable=self.workers_var,
            bg="#2a2a2a",
            fg="#dddddd",
            justify="left",
            anchor="w",
        ).pack(fill="x", padx=8, pady=2)

    def clear(self) -> None:
        self.selected_node_id = None
        self.title_var.set("Selected Node")
        self.status_var.set("Status: -")
        self.recipe_var.set("Recipe: -")
        self.contents_var.set("Contents: -")
        self.workers_var.set("Workers: -")

    def update_node_info(
        self,
        *,
        node_name: str,
        recipe_name: str,
        contents_text: str,
        workers_assigned: int,
        workers_total: int,
        node_state: str,
    ) -> None:
        self.title_var.set(node_name)
        self.recipe_var.set(f"Recipe: {recipe_name}")
        self.contents_var.set(f"Contents:\n{contents_text}")
        self.workers_var.set(f"Workers: {workers_assigned} / {workers_total}")

        state = node_state.lower()

        if "construction" in state:
            self.status_var.set("Status: Building")
        elif "running" in state:
            self.status_var.set("Status: Working")
        elif "ready" in state or "idle" in state:
            self.status_var.set("Status: Waiting for inputs")
        else:
            self.status_var.set(f"Status: {node_state}")