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

public bool add_cache_entry(Gtk.Window? parent,
              out CacheType type,
              out string name,
              out string value,
              out string help)
{
  bool success = false;

  var dialog = new AddCacheEntryDialog();

  if (parent != null)
  {
    dialog.set_transient_for(parent);
  }

  if (dialog.run() == Gtk.ResponseType.OK)
  {
    type = dialog.get_cache_type();
    name = dialog.get_name();
    value = dialog.get_value();
    help = dialog.get_description();
    success = true;
  }
  else
  {
    type = CacheType.INTERNAL;
    name = null;
    value = null;
    help = null;
  }

  dialog.destroy();
  return success;
}

[GtkTemplate (ui = "/net/purplekarrot/cmake/add_cache_entry.ui")]
class AddCacheEntryDialog : Gtk.Dialog
{
  [GtkChild]
  private Gtk.Entry name_input;

  [GtkChild]
  private Gtk.Entry description_input;

  [GtkChild]
  private Gtk.ComboBoxText type_input;

  [GtkChild]
  private Gtk.Switch bool_input;

  [GtkChild]
  private Gtk.Entry string_input;

  [GtkChild]
  private Gtk.FileChooserButton path_input;

  [GtkChild]
  private Gtk.Stack input_stack;

  public AddCacheEntryDialog()
  {
    Object(use_header_bar: 1);
    this.border_width = 10;
  }

  [GtkCallback]
  private void type_changed()
  {
    switch (type_input.active)
    {
    case 0:
      bool_input.active = false;
      input_stack.visible_child = bool_input;
      break;
    case 1:
      path_input.title = "Select a directory";
      path_input.action = Gtk.FileChooserAction.SELECT_FOLDER;
      path_input.unselect_all();
      input_stack.visible_child = path_input;
      break;
    case 2:
      path_input.title = "Select a file";
      path_input.action = Gtk.FileChooserAction.OPEN;
      path_input.unselect_all();
      input_stack.visible_child = path_input;
      break;
    case 3:
      string_input.delete_text(0, -1);
      input_stack.visible_child = string_input;
      break;
    }
  }

  public CacheType get_cache_type()
  {
    return (CacheType) this.type_input.active;
  }

  public string get_name()
  {
    return this.name_input.text;
  }

  public string get_value()
  {
    switch (type_input.active)
    {
    case 0:
      return bool_input.active ? "1" : "0";
    case 1:
    case 2:
      return path_input.get_filename();
    case 3:
      return string_input.text;
    }

    assert_not_reached();
  }

  public string get_description()
  {
    return this.description_input.text;
  }
}

} // namespace CMake
