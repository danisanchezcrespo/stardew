import tkinter as tk


class WorldStatusPanel(tk.Frame):
    def __init__(self, master) -> None:
        super().__init__(master, bg="#2a2a2a", bd=1, relief="solid")

        self.title_label = tk.Label(
            self,
            text="World Status",
            bg="#2a2a2a",
            fg="white",
            font=("Arial", 11, "bold"),
            anchor="w",
        )
        self.title_label.pack(fill="x", padx=8, pady=(6, 4))

        self.buildings_var = tk.StringVar(value="Buildings: 0")
        self.residents_var = tk.StringVar(value="Residents: 0")
        self.unemployment_var = tk.StringVar(value="Unemployment: 0%")
        self.food_var = tk.StringVar(value="Food reserves: 0")
        self.growth_var = tk.StringVar(value="Growth: Stable")

        self._make_row(self.buildings_var)
        self._make_row(self.residents_var)
        self._make_row(self.unemployment_var)
        self._make_row(self.food_var)
        self._make_row(self.growth_var)

    def _make_row(self, text_var: tk.StringVar) -> None:
        label = tk.Label(
            self,
            textvariable=text_var,
            bg="#2a2a2a",
            fg="#dddddd",
            font=("Arial", 10),
            anchor="w",
        )
        label.pack(fill="x", padx=8, pady=2)

    def update_status(
        self,
        *,
        building_count: int,
        resident_count: int,
        unemployment_percent: float,
        food_reserves: int,
        growth_text: str,
    ) -> None:
        self.buildings_var.set(f"Buildings: {building_count}")
        self.residents_var.set(f"Residents: {resident_count}")
        self.unemployment_var.set(f"Unemployment: {unemployment_percent:.1f}%")
        self.food_var.set(f"Food reserves: {food_reserves}")
        self.growth_var.set(f"Growth: {growth_text}")