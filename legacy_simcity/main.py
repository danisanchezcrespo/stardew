from tkinter import Tk
from ui.app_window import AppWindow


def main() -> None:
    root = Tk()
    app = AppWindow(root)
    app.run()


if __name__ == "__main__":
    main()