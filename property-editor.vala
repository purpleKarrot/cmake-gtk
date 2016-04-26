/*
 * Copyright (C) 2015 Daniel Pfeifer <daniel@pfeifer-mail.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace CMake
{

class PropertyEditor : Gtk.Box
{
  public signal void value_changed(string value);

  private Gtk.Widget create_switch(string init)
  {
    var foo = new Gtk.Switch();
    foo.active = CMake.is_on(init);
    foo.state_set.connect((state) =>
    {
      this.value_changed(state ? "ON" : "OFF");
      return false;
    });
    return foo;
  }

  private Gtk.Widget create_file_chooser(string init)
  {
    var foo = new Gtk.FileChooserButton("Select a file", Gtk.FileChooserAction.OPEN);
    foo.set_filename(init);
    foo.width_chars = 20;
    foo.selection_changed.connect(() =>
    {
      this.value_changed(foo.get_filename());
    });
    return foo;
  }

  private Gtk.Widget create_path_chooser(string init)
  {
    var foo = new Gtk.FileChooserButton("Select a directory", Gtk.FileChooserAction.SELECT_FOLDER);
    foo.set_filename(init);
    foo.width_chars = 20;
    foo.selection_changed.connect(() =>
    {
      this.value_changed(foo.get_filename());
    });
    return foo;
  }

  private Gtk.Widget create_entry(string init)
  {
    var foo = new Gtk.Entry();
    foo.set_text(init);
    foo.width_chars = 20;
    foo.changed.connect(() =>
    {
      this.value_changed(foo.get_text());
    });
    return foo;
  }

  private Gtk.Widget create_selection(string init, string values)
  {
    var foo = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

    Gtk.RadioButton? button = null;
    foreach (string s in values.split(";"))
    {
      button = new Gtk.RadioButton.with_label_from_widget(button, s);

      if (s == init)
      {
        button.set_active(true);
      }

      var capture = button;
      button.toggled.connect(() =>
      {
        if (capture.active)
        {
          this.value_changed(s);
        }
      });

      foo.pack_start(button, false, false, 0);
    }

    return foo;
  }

  private Gtk.Widget create_mod(CacheEntry entry)
  {
    switch (entry.type)
    {
    case CacheType.BOOL:
      return create_switch(entry.value);

    case CacheType.PATH:
      return create_path_chooser(entry.value);

    case CacheType.FILEPATH:
      return create_file_chooser(entry.value);

    case CacheType.STRING:
      string? strings = entry.strings;
      if (strings != null)
      {
        return create_selection(entry.value, strings);
      }
      break;
    }

    return create_entry(entry.value);
  }

  public PropertyEditor(CacheEntry entry)
  {
    Object(orientation: Gtk.Orientation.VERTICAL, spacing: 10);
    this.border_width = 10;

    var label = new Gtk.Label(null);
    label.max_width_chars = 50;
    label.wrap = true;
    label.label = entry.help;
    this.pack_start(label, false, false, 0);

    if (entry.type == CacheType.STATIC)
    {
      return;
    }

    Gtk.Widget widget = create_mod(entry);
    widget.halign = Gtk.Align.CENTER;
    this.pack_start(widget, false, false, 0);
  }
}

} // namespace CMake
