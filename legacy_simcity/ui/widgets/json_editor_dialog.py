import copy
import json
import tkinter as tk
from tkinter import ttk, messagebox


class JsonEditorDialog(tk.Toplevel):
    def __init__(self, parent, json_data, on_save):
        super().__init__(parent)
        self.title("Structured JSON Editor")
        self.geometry("1180x720")
        self.configure(bg="#202020")
        self.transient(parent)
        self.grab_set()

        self._on_save = on_save
        self._data = copy.deepcopy(json_data)

        if not isinstance(self._data, dict):
            raise ValueError("JSON editor expects a top-level dict.")

        self._data.setdefault("entities", [])
        self._data.setdefault("edges", [])

        self._current_section = "entities"
        self._field_rows = []
        self._selected_index = None

        self._build_ui()
        self._refresh_list()

        if self._get_current_items():
            self._select_item(0)

    def _get_current_items(self):
        return self._data[self._current_section]

    def _get_section_title(self):
        return "Entities" if self._current_section == "entities" else "Edges"

    def _get_new_item_template(self):
        if self._current_section == "entities":
            return {
                "id": "",
                "label": "",
                "color": "#888888",
                "construction_cost": {},
                "initial_amounts": {},
                "max_amounts": {},
                "recipe_inputs": {},
                "recipe_outputs": {},
                "source_rate_per_sec": 0.0,
                "process_time_sec": 0.0,

                # Worker / shared-resource system
                "shared_resource_modifiers": {},
                "workers_required": 0.0,
                "worker_priority": 0,
                "min_worker_efficiency": 0.0,
            }

        return {
            "id": "",
            "label": "",
            "color": "#FFD966",
            "speed": 50.0,
            "capacity_per_trip": 10.0,
            "mode": "one_way",
            "transport_resource": "",
            "units_per_edge": 1.0,
            "initial_pool_units": 0.0,
        }

    def _item_label(self, item, index):
        if not isinstance(item, dict):
            return f"{index}: <non-dict>"
        item_id = item.get("id", "")
        label = item.get("label", "")
        return f"{index}: {item_id} | {label}"

    def _parse_value(self, raw_text):
        raw_text = raw_text.strip()
        if raw_text == "":
            return ""
        try:
            return json.loads(raw_text)
        except json.JSONDecodeError:
            return raw_text

    def _value_to_text(self, value):
        if isinstance(value, str):
            return value
        return json.dumps(value, ensure_ascii=False)

    def _build_ui(self):
        self.columnconfigure(0, weight=0)
        self.columnconfigure(1, weight=1)
        self.rowconfigure(0, weight=1)

        left = tk.Frame(self, bg="#2a2a2a", width=340)
        left.grid(row=0, column=0, sticky="nsew")
        left.grid_propagate(False)

        section_bar = tk.Frame(left, bg="#2a2a2a")
        section_bar.pack(fill="x", padx=10, pady=(10, 6))

        self.entities_btn = tk.Button(
            section_bar,
            text="ENTITIES",
            command=lambda: self._switch_section("entities"),
            bg="#555555",
            fg="white",
            relief="flat",
            padx=10,
        )
        self.entities_btn.pack(side="left", padx=(0, 6))

        self.edges_btn = tk.Button(
            section_bar,
            text="EDGES",
            command=lambda: self._switch_section("edges"),
            bg="#333333",
            fg="white",
            relief="flat",
            padx=10,
        )
        self.edges_btn.pack(side="left")

        left_header = tk.Frame(left, bg="#2a2a2a")
        left_header.pack(fill="x", padx=10, pady=(10, 6))

        self.list_title_var = tk.StringVar(value="Entities")
        tk.Label(
            left_header,
            textvariable=self.list_title_var,
            bg="#2a2a2a",
            fg="white",
            font=("Arial", 12, "bold"),
        ).pack(side="left")

        self.new_button = tk.Button(
            left_header,
            text="+ New",
            command=self._on_add_item,
            bg="#3a7a3a",
            fg="white",
            relief="flat",
            padx=10,
        )
        self.new_button.pack(side="right")

        self.item_listbox = tk.Listbox(
            left,
            bg="#1e1e1e",
            fg="white",
            selectbackground="#4a6ea8",
            activestyle="none",
        )
        self.item_listbox.pack(fill="both", expand=True, padx=10, pady=(0, 10))
        self.item_listbox.bind("<<ListboxSelect>>", self._on_item_selected)

        item_buttons = tk.Frame(left, bg="#2a2a2a")
        item_buttons.pack(fill="x", padx=10, pady=(0, 10))

        self.delete_button = tk.Button(
            item_buttons,
            text="Delete",
            command=self._on_delete_item,
            bg="#8a3a3a",
            fg="white",
            relief="flat",
            padx=10,
        )
        self.delete_button.pack(fill="x")

        right = tk.Frame(self, bg="#202020")
        right.grid(row=0, column=1, sticky="nsew")
        right.columnconfigure(0, weight=1)
        right.rowconfigure(1, weight=1)

        title_bar = tk.Frame(right, bg="#202020")
        title_bar.grid(row=0, column=0, sticky="ew", padx=12, pady=(12, 8))

        self.item_title_var = tk.StringVar(value="No item selected")
        tk.Label(
            title_bar,
            textvariable=self.item_title_var,
            bg="#202020",
            fg="white",
            font=("Arial", 12, "bold"),
        ).pack(side="left")

        self.form_canvas = tk.Canvas(right, bg="#202020", highlightthickness=0)
        self.form_canvas.grid(row=1, column=0, sticky="nsew", padx=12, pady=(0, 12))

        scrollbar = ttk.Scrollbar(right, orient="vertical", command=self.form_canvas.yview)
        scrollbar.grid(row=1, column=1, sticky="ns", pady=(0, 12))

        self.form_canvas.configure(yscrollcommand=scrollbar.set)

        self.form_frame = tk.Frame(self.form_canvas, bg="#202020")
        self.form_window = self.form_canvas.create_window((0, 0), window=self.form_frame, anchor="nw")

        self.form_frame.bind("<Configure>", self._on_form_configure)
        self.form_canvas.bind("<Configure>", self._on_canvas_configure)

        bottom = tk.Frame(right, bg="#202020")
        bottom.grid(row=2, column=0, columnspan=2, sticky="ew", padx=12, pady=(0, 12))

        tk.Button(
            bottom,
            text="Cancel",
            command=self.destroy,
            bg="#4a4a4a",
            fg="white",
            relief="flat",
            padx=12,
        ).pack(side="right", padx=(8, 0))

        tk.Button(
            bottom,
            text="Save",
            command=self._on_save_clicked,
            bg="#3a7a3a",
            fg="white",
            relief="flat",
            padx=12,
        ).pack(side="right")

        self._refresh_section_buttons()

    def _refresh_section_buttons(self):
        self.entities_btn.config(bg="#555555" if self._current_section == "entities" else "#333333")
        self.edges_btn.config(bg="#555555" if self._current_section == "edges" else "#333333")
        self.list_title_var.set(self._get_section_title())

    def _on_form_configure(self, _event):
        self.form_canvas.configure(scrollregion=self.form_canvas.bbox("all"))

    def _on_canvas_configure(self, event):
        self.form_canvas.itemconfig(self.form_window, width=event.width)

    def _switch_section(self, section_name):
        if section_name == self._current_section:
            return

        self._commit_form_to_selected_item()
        self._current_section = section_name
        self._selected_index = None
        self._clear_form()
        self._refresh_section_buttons()
        self._refresh_list()

        if self._get_current_items():
            self._select_item(0)

    def _refresh_list(self):
        items = self._get_current_items()
        self.item_listbox.delete(0, tk.END)

        for i, item in enumerate(items):
            self.item_listbox.insert(tk.END, self._item_label(item, i))

    def _select_item(self, index):
        items = self._get_current_items()
        if not items:
            self._selected_index = None
            self.item_title_var.set("No item selected")
            self._clear_form()
            return

        index = max(0, min(index, len(items) - 1))
        self._selected_index = index

        self.item_listbox.selection_clear(0, tk.END)
        self.item_listbox.selection_set(index)
        self.item_listbox.activate(index)

        self._load_item_into_form(items[index])

    def _on_item_selected(self, _event):
        selection = self.item_listbox.curselection()
        if not selection:
            return

        self._commit_form_to_selected_item()
        self._select_item(selection[0])

    def _clear_form(self):
        for widget in self.form_frame.winfo_children():
            widget.destroy()
        self._field_rows.clear()

    def _load_item_into_form(self, item):
        self._clear_form()

        self.item_title_var.set(
            self._item_label(item, self._selected_index if self._selected_index is not None else 0)
        )

        if not isinstance(item, dict):
            tk.Label(
                self.form_frame,
                text="Selected item is not a dict.",
                bg="#202020",
                fg="tomato",
            ).pack(anchor="w", pady=10)
            return

        for key, value in item.items():
            self._create_field_row(key, value)

    def _create_field_row(self, key="", value=""):
        row = tk.Frame(self.form_frame, bg="#2a2a2a", padx=8, pady=8)
        row.pack(fill="x", expand=True, pady=(0, 8))

        key_label = tk.Label(
            row,
            text=key,
            bg="#2a2a2a",
            fg="white",
            anchor="w",
            font=("Arial", 10, "bold"),
            width=18,
        )
        key_label.grid(row=0, column=0, sticky="w", padx=(0, 12))

        value_var = tk.StringVar(value=self._value_to_text(value))
        value_entry = tk.Entry(
            row,
            textvariable=value_var,
            bg="#1e1e1e",
            fg="white",
            insertbackground="white",
        )
        value_entry.grid(row=0, column=1, sticky="ew")

        row.columnconfigure(1, weight=1)

        self._field_rows.append({
            "frame": row,
            "key": key,
            "value_var": value_var,
        })

    def _commit_form_to_selected_item(self):
        if self._selected_index is None:
            return

        items = self._get_current_items()
        if not (0 <= self._selected_index < len(items)):
            return

        old_item = items[self._selected_index]
        if not isinstance(old_item, dict):
            return

        new_item = {}
        for row in self._field_rows:
            key = row["key"]
            value = self._parse_value(row["value_var"].get())
            new_item[key] = value

        items[self._selected_index] = new_item
        self._refresh_list()

    def _on_add_item(self):
        self._commit_form_to_selected_item()
        items = self._get_current_items()
        items.append(self._get_new_item_template())
        self._refresh_list()
        self._select_item(len(items) - 1)

    def _on_delete_item(self):
        if self._selected_index is None:
            return

        items = self._get_current_items()
        if not items:
            return

        confirm = messagebox.askyesno(
            "Delete Item",
            f"Are you sure you want to delete this {self._get_section_title()[:-1].lower()}?",
            parent=self,
        )
        if not confirm:
            return

        del items[self._selected_index]
        self._refresh_list()

        if items:
            self._select_item(min(self._selected_index, len(items) - 1))
        else:
            self._selected_index = None
            self.item_title_var.set("No item selected")
            self._clear_form()

    def _on_save_clicked(self):
        try:
            self._commit_form_to_selected_item()
            self._on_save(copy.deepcopy(self._data))
            self.destroy()
        except Exception as exc:
            messagebox.showerror("Save Error", str(exc), parent=self)