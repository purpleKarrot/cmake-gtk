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

[GtkTemplate (ui = "/net/purplekarrot/cmake/cmake_setup.ui")]
public class SetupWindow : Gtk.ApplicationWindow
{
  private CMake.Wrapper cmake = new CMake.Wrapper();
  private CMake.Cache cache = new CMake.Cache();

  private Gtk.TreeModelFilter filtered_model;

  private Gtk.TextBuffer output_buffer = new Gtk.TextBuffer(null);

  protected bool show_advanced
  {
    get
    {
      return this.show_advanced_;
    }

    set
    {
      this.show_advanced_ = value;
      this.filtered_model.refilter();
    }
  }

  private bool show_advanced_ = false;

  [GtkChild]
  private Gtk.MenuButton gears;

  [GtkChild]
  private Gtk.ToggleButton search;

  [GtkChild]
  private Gtk.SearchBar searchbar;

  [GtkChild]
  private Gtk.FileChooserButton source_directory;

  [GtkChild]
  private Gtk.FileChooserButton binary_directory;

  [GtkChild]
  private Gtk.TreeView cache_view;

  [GtkChild]
  private Gtk.ToolButton add_entry_toolbutton;

  [GtkChild]
  private Gtk.ToolButton remove_entry_toolbutton;

  [GtkChild]
  private Gtk.TextView output_view;

  [GtkCallback]
  private void do_configure()
  {
    this.output_buffer.set_text("", 0);

    if (this.cache.lookup_value("CMAKE_GENERATOR") == null)
    {
      if (!run_toolchain_assistant(cmake, cache))
      {
        return;
      }
    }

//    //Name of external makefile project generator.
//    CMAKE_EXTRA_GENERATOR:INTERNAL=Sublime Text 2

//    //Name of generator.
//    CMAKE_GENERATOR:INTERNAL=Ninja

//    //Name of generator platform.
//    CMAKE_GENERATOR_PLATFORM:INTERNAL=

//    //Name of generator toolset.
//    CMAKE_GENERATOR_TOOLSET:INTERNAL=

//    //Start directory with the top level CMakeLists.txt file for this project
//    CMAKE_HOME_DIRECTORY:INTERNAL=/home/daniel/Projects/CMakeDialog

    string bindir = binary_directory.get_filename();

    cache.save(bindir);
    cmake.configure();
    cache.load(bindir);
  }

  [GtkCallback]
  private void do_build()
  {
    this.output_buffer.set_text("", 0);

    string bindir = binary_directory.get_filename();

    cache.save(bindir);
    cmake.build();
    cache.load(bindir);
  }

  [GtkCallback]
  private void search_text_changed()
  {
  }

  [GtkCallback]
  private void binary_directory_selected()
  {
    this.cache.load(binary_directory.get_filename());
    string? source_dir = this.cache.lookup_value("CMAKE_HOME_DIRECTORY");
    if (source_dir != null)
    {
      this.source_directory.select_filename(source_dir);
    }
    else
    {
      this.source_directory.unselect_all();
    }
  }

  [GtkCallback]
  private void cursor_changed()
  {
    Gtk.TreePath path;
    this.cache_view.get_cursor(out path, null);
    this.remove_entry_toolbutton.sensitive = (path != null);
  }

  [GtkCallback]
  private void add_entry()
  {
    CacheType type;
    string name, value, help;
    if (CMake.add_cache_entry(this, out type, out name, out value, out help))
    {
      this.cache.add_entry(type, name, value, help);
    }
  }

  [GtkCallback]
  private void remove_entry()
  {
    Gtk.TreePath path;
    this.cache_view.get_cursor(out path, null);
    path = this.filtered_model.convert_path_to_child_path(path);
    this.cache.remove_entry(path);
  }

  [GtkCallback]
  void row_activated(Gtk.TreePath path, Gtk.TreeViewColumn column)
  {
    Gdk.Rectangle rect;
    this.cache_view.get_cell_area(path, column, out rect);
    this.cache_view.convert_bin_window_to_widget_coords(rect.x, rect.y, out rect.x, out rect.y);

    var popover = new Gtk.Popover(this.cache_view);
    popover.set_pointing_to(rect);

    Gtk.TreeIter iter;
    Gtk.TreePath child_path;
    child_path = this.filtered_model.convert_path_to_child_path(path);
    this.cache.get_iter(out iter, child_path);

    var editor = new PropertyEditor(this.cache.get_entry(iter));
    editor.value_changed.connect((value) =>
    {
      this.cache.change_value(child_path, iter, value);
    });

    popover.add(editor);
    popover.hide.connect(() => popover.destroy());
    popover.show_all();
  }

  private bool row_visible(Gtk.TreeModel model, Gtk.TreeIter iter)
  {
    unowned CacheEntry entry = this.cache.get_entry(iter);
    if (entry.type == CacheType.STATIC)
    {
      return false;
    }

    if (entry.is_advanced && !this.show_advanced)
    {
      return false;
    }

    return true;
  }

  public SetupWindow(Gtk.Application app)
  {
    Object(application: app);

    search.bind_property("active", searchbar, "search-mode-enabled",
        BindingFlags.BIDIRECTIONAL);

    add_action(new PropertyAction("show-advanced", this, "show-advanced"));

    var builder = new Gtk.Builder.from_resource("/net/purplekarrot/cmake/gears-menu.ui");
    gears.menu_model = builder.get_object("menu") as GLib.MenuModel;

    this.filtered_model = new Gtk.TreeModelFilter(this.cache, null);
    this.filtered_model.set_visible_func(this.row_visible);
    this.cache_view.set_model(this.filtered_model);

    output_view.set_buffer(output_buffer);
    output_view.override_font(Pango.FontDescription.from_string("monospace"));

    this.cmake.stdout_message.connect((msg) =>
    {
      Gtk.TextIter iter;
      this.output_buffer.get_end_iter(out iter);
      this.output_buffer.insert(ref iter, msg, -1);
      this.output_view.scroll_to_iter(iter, 0, false, 0, 0);
    });

    this.binary_directory.select_filename(Environment.get_current_dir());
    this.binary_directory_selected();
  }
}

} // namespace CMake
