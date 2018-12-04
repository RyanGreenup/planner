public class Widgets.Popovers.LabelsPopover : Gtk.Popover {
    private Gtk.Stack stack;
    public Gtk.ListBox labels_listbox;
    private Gtk.Button add_button;
    public const string COLOR_CSS = """
        .label-preview {
            background-image:
                linear-gradient(
                    to bottom,
                    shade (
                    %s,
                        1.3
                    ),
                    %s
                );
            border: 1px solid shade (%s, 0.9);
            border-radius: 3px;
            box-shadow:
                inset 0 0 0 1px alpha (#fff, 0.05),
                inset 0 1px 0 0 alpha (#fff, 0.25),
                inset 0 -1px 0 0 alpha (#fff, 0.1),
                0 1px 2px alpha (#000, 0.3);
            color: %s;
            padding: 1 6px;
            font-size: 11px;
            font-weight: 700;
            margin: 2px;
            min-width: 18px;
            min-height: 18px;
            text-shadow: 0 1px 1px alpha (#000, 0.3);
        }
    """;
    public signal void on_selected_label (Objects.Label label);
    public LabelsPopover (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.RIGHT
        );
    }

    construct {
        width_request = 290;
        height_request = 300;

        var title_label = new Gtk.Label ("<small>%s</small>".printf (Application.utils.LABELS_STRING));
        title_label.halign = Gtk.Align.CENTER;
        title_label.hexpand = true;
        title_label.use_markup = true;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        add_button = new Gtk.Button.with_label (_("Create label"));
        add_button.margin = 6;
        add_button.tooltip_text = _("Add new label");

        labels_listbox = new Gtk.ListBox  ();
        labels_listbox.activate_on_single_click = true;
        labels_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        labels_listbox.expand = true;

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add (labels_listbox);

        var list_labels_grid = new Gtk.Grid ();;
        list_labels_grid.expand = true;
        list_labels_grid.orientation = Gtk.Orientation.VERTICAL;
        list_labels_grid.attach (title_label, 0, 0, 1, 1);
        list_labels_grid.attach (scrolled_window, 0, 2, 1, 1);
        list_labels_grid.attach (add_button, 0, 3, 1, 1);

        var title_new_label = new Gtk.Label ("<small>%s</small>".printf (_("Label")));
        title_new_label.halign = Gtk.Align.CENTER;
        title_new_label.hexpand = true;
        title_new_label.use_markup = true;
        title_new_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var label_preview = new Gtk.Label ("Label name");
        label_preview.valign = Gtk.Align.CENTER;
        label_preview.get_style_context ().add_class ("label-preview");

        var label_entry = new Gtk.Entry ();
        label_entry.hexpand = true;
        label_entry.placeholder_text = _("Priority: Low");

        var random_button = new Gtk.Button.from_icon_name ("system-reboot-symbolic", Gtk.IconSize.MENU);

        var color_hex_entry = new Gtk.Entry ();
        color_hex_entry.hexpand = true;
        color_hex_entry.placeholder_text = "#7239b3";
        color_hex_entry.max_length = 7;

        var color_button  = new Gtk.ColorButton ();

        var color_grid = new Gtk.Grid ();
        color_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        color_grid.add (color_hex_entry);
        color_grid.add (random_button);
        color_grid.add (color_button);

        var submit_button = new Gtk.Button.with_label (_("Create label"));
        submit_button.sensitive = false;
        submit_button.valign = Gtk.Align.END;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.tooltip_text = _("Add new label");

        var back_button = new Gtk.Button.with_label (_("Cancel"));
        back_button.valign = Gtk.Align.END;
        back_button.tooltip_text = _("Cancel");

        var bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        bottom_box.vexpand = true;
        bottom_box.homogeneous = true;
        bottom_box.valign = Gtk.Align.END;
        bottom_box.pack_start (back_button, true, true, 0);
        bottom_box.pack_start (submit_button, true, true, 0);

        var add_label_grid = new Gtk.Grid ();
        add_label_grid.margin = 6;
        add_label_grid.margin_top = 0;
        add_label_grid.expand = true;
        add_label_grid.row_spacing = 3;
        add_label_grid.orientation = Gtk.Orientation.VERTICAL;

        add_label_grid.add (title_new_label);
        add_label_grid.add (new Granite.HeaderLabel (_("Preview")));
        add_label_grid.add (label_preview);
        add_label_grid.add (new Granite.HeaderLabel (_("Name")));
        add_label_grid.add (label_entry);
        add_label_grid.add (new Granite.HeaderLabel (_("Color")));
        add_label_grid.add (color_grid);
        add_label_grid.add (bottom_box);

        label_entry.changed.connect (() => {
            if (label_entry.text == "") {
                submit_button.sensitive = false;
                label_preview.label = "";
            } else {
                submit_button.sensitive = true;
                label_preview.label = label_entry.text;
            }
        });

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        stack.add_named (list_labels_grid, "list_labels_grid");
        stack.add_named (add_label_grid, "add_label_grid");

        stack.visible_child_name = "list_labels_grid";

        add (stack);
        update_label_list ();

        add_button.clicked.connect (() => {
            stack.visible_child_name = "add_label_grid";
            label_entry.grab_focus ();
        });

        back_button.clicked.connect (() => {
            stack.visible_child_name = "list_labels_grid";
            label_entry.grab_focus ();
        });

        submit_button.clicked.connect (() => {
            var label = new Objects.Label ();
            label.name = label_entry.text;
            label.color = Application.utils.rgb_to_hex_string (color_button.rgba);

            if (Application.database.add_label (label) == Sqlite.DONE) {
                label_entry.text = "";
                stack.visible_child_name = "list_labels_grid";

                update_label_list ();
                show_all ();
            }
        });

        labels_listbox.row_activated.connect ((item_row) => {
            var row = item_row as Widgets.LabelRow;
            on_selected_label (row.label);
        });

        color_hex_entry.changed.connect (() => {
            var rgba = Gdk.RGBA ();
            if (rgba.parse (color_hex_entry.text)) {
                color_button.rgba = rgba;
                add_styles (Application.utils.rgb_to_hex_string (color_button.rgba));
            }
        });

        random_button.clicked.connect (() => {
            string random_color = "rgb(%i, %i, %i)".printf (GLib.Random.int_range (0, 255), GLib.Random.int_range (0, 255), GLib.Random.int_range (0, 255));
            var rgba = Gdk.RGBA ();
            rgba.parse (random_color);

            color_button.rgba = rgba;
            color_hex_entry.text = Application.utils.rgb_to_hex_string (color_button.rgba);

            add_styles (Application.utils.rgb_to_hex_string (rgba));
        });

        color_button.color_set.connect (() => {
            color_hex_entry.text = Application.utils.rgb_to_hex_string (color_button.rgba);
            add_styles (Application.utils.rgb_to_hex_string (color_button.rgba));
        });
    }

    public void update_label_list () {
        foreach (Gtk.Widget element in labels_listbox.get_children ()) {
            labels_listbox.remove (element);
        }

        var all_labels = new Gee.ArrayList<Objects.Label?> ();
        all_labels = Application.database.get_all_labels ();

        foreach (var label in all_labels) {
            var row = new Widgets.LabelRow (label);
            labels_listbox.add (row);
        }
    }

    private void add_styles (string color_hex) {
        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                color_hex,                  // Background Color
                color_hex,
                color_hex,
                Application.utils.convert_invert (color_hex)  // Text Color
            );
            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }
}
