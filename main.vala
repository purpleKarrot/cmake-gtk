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

class Application : Gtk.Application
{
  private Gtk.Window window = null;

  protected override void activate()
  {
    window = new SetupWindow(this);
    window.show();
  }

  protected override void startup()
  {
    base.startup();

    var action = new SimpleAction("about", null);
    action.activate.connect(about);
    this.add_action(action);

    action = new SimpleAction("quit", null);
    action.activate.connect(this.quit);
    this.add_action(action);

    var builder = new Gtk.Builder.from_resource("/net/purplekarrot/cmake/app-menu.ui");
    this.app_menu = builder.get_object("appmenu") as MenuModel;
  }

  void new_callback(SimpleAction action, Variant? parameter)
  {
    print ("You clicked \"New\".\n");
  }

  void open_callback(SimpleAction action, Variant? parameter)
  {
      print ("You clicked \"Open\".\n");
  }

  void about()
  {
    const string authors[] = {"Daniel Pfeifer"};
    Gtk.show_about_dialog(window,
      "authors", authors,
      "copyright", "Copyright (c) 2015 Daniel Pfeifer",
      "license-type", Gtk.License.GPL_3_0,
      "program-name", "CMake Cache Editor",
      "version", "0.1",
      "website", "http://purplekarrot.net",
      "website-label", "purplekarrot.net"
    );
  }
}

int main(string[] args)
{
  return new Application().run(args);
}

} // namespace CMake
