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

public bool run_toolchain_assistant(CMake.Wrapper cmake, CMake.Cache cache)
{
  bool success = false;

  var loop = new MainLoop();
  var assistant = new ToolchainAssistant(cmake, cache);

  assistant.close.connect(() =>
  {
    success = true;
    assistant.destroy();
    loop.quit();
  });

  assistant.cancel.connect(() =>
  {
    assistant.destroy();
    loop.quit();
  });

  assistant.show_all();
  loop.run();

  return success;
}

[GtkTemplate (ui = "/net/purplekarrot/cmake/toolchain_assistant.ui")]
class ToolchainAssistant : Gtk.Assistant
{
  [GtkChild]
  private Gtk.ComboBoxText select_generator;

  [GtkChild]
  private Gtk.RadioButton use_default;

  [GtkChild]
  private Gtk.RadioButton specify_compilers;

  [GtkChild]
  private Gtk.RadioButton specify_toolchain;

  [GtkChild]
  private Gtk.RadioButton specify_options;

  [GtkChild]
  private Gtk.Widget intro_page;

  [GtkChild]
  private Gtk.FileChooserButton toolchain_file;

  [GtkCallback]
  private void toggle_default()
  {
    this.set_page_type(this.intro_page, use_default.active
        ? Gtk.AssistantPageType.CONFIRM
        : Gtk.AssistantPageType.CONTENT);
  }

  private int forward_page(int current_page)
  {
    if (current_page != 0 || use_default.active)
    {
      return -1;
    }

    if (specify_compilers.active)
    {
      return 1;
    }

    if (specify_toolchain.active)
    {
      return 2;
    }

    return 3;
  }

  private void create_cache_entries()
  {
    if (specify_toolchain.active)
    {
      this.cache.add_entry(CacheType.FILEPATH, "CMAKE_TOOLCHAIN_FILE",
          toolchain_file.get_filename(), "Cross Compile ToolChain File");
    }
    else if (specify_compilers.active)
    {
//      QString fortranCompiler = dialog.getFortranCompiler();
//      if(!fortranCompiler.isEmpty())
//      {
//        m->insertProperty(QCMakeProperty::FILEPATH, "CMAKE_Fortran_COMPILER",
//            "Fortran compiler.", fortranCompiler, false);
//      }
//      QString cxxCompiler = dialog.getCXXCompiler();
//      if(!cxxCompiler.isEmpty())
//      {
//        m->insertProperty(QCMakeProperty::FILEPATH, "CMAKE_CXX_COMPILER",
//            "CXX compiler.", cxxCompiler, false);
//      }
//
//      QString cCompiler = dialog.getCCompiler();
//      if(!cCompiler.isEmpty())
//      {
//        m->insertProperty(QCMakeProperty::FILEPATH, "CMAKE_C_COMPILER",
//            "C compiler.", cCompiler, false);
//      }
    }
    else if (specify_options.active)
    {
//      QString fortranCompiler = dialog.getFortranCompiler();
//      if(!fortranCompiler.isEmpty())
//      {
//        m->insertProperty(QCMakeProperty::FILEPATH, "CMAKE_Fortran_COMPILER",
//            "Fortran compiler.", fortranCompiler, false);
//      }
//
//      QString mode = dialog.getCrossIncludeMode();
//      m->insertProperty(QCMakeProperty::STRING, "CMAKE_FIND_ROOT_PATH_MODE_INCLUDE",
//          tr("CMake Find Include Mode"), mode, false);
//      mode = dialog.getCrossLibraryMode();
//      m->insertProperty(QCMakeProperty::STRING, "CMAKE_FIND_ROOT_PATH_MODE_LIBRARY",
//          tr("CMake Find Library Mode"), mode, false);
//      mode = dialog.getCrossProgramMode();
//      m->insertProperty(QCMakeProperty::STRING, "CMAKE_FIND_ROOT_PATH_MODE_PROGRAM",
//          tr("CMake Find Program Mode"), mode, false);
//
//      QString rootPath = dialog.getCrossRoot();
//      m->insertProperty(QCMakeProperty::PATH, "CMAKE_FIND_ROOT_PATH",
//          tr("CMake Find Root Path"), rootPath, false);
//
//      QString systemName = dialog.getSystemName();
//      m->insertProperty(QCMakeProperty::STRING, "CMAKE_SYSTEM_NAME",
//          tr("CMake System Name"), systemName, false);
//      QString systemVersion = dialog.getSystemVersion();
//      m->insertProperty(QCMakeProperty::STRING, "CMAKE_SYSTEM_VERSION",
//          tr("CMake System Version"), systemVersion, false);
//      QString cxxCompiler = dialog.getCXXCompiler();
//      m->insertProperty(QCMakeProperty::FILEPATH, "CMAKE_CXX_COMPILER",
//          tr("CXX compiler."), cxxCompiler, false);
//      QString cCompiler = dialog.getCCompiler();
//      m->insertProperty(QCMakeProperty::FILEPATH, "CMAKE_C_COMPILER",
//          tr("C compiler."), cCompiler, false);
    }
  }

  public ToolchainAssistant(CMake.Wrapper cmake, CMake.Cache cache)
  {
    this.cmake = cmake;
    this.cache = cache;

    this.set_forward_page_func(forward_page);
    this.apply.connect(create_cache_entries);

    this.select_generator.remove_all();
    foreach (unowned string generator in cmake.available_generators())
    {
      this.select_generator.append_text(generator);
    }
    this.select_generator.set_active(0);
  }

  private CMake.Wrapper cmake;
  private CMake.Cache cache;
}

} // namespace CMake
