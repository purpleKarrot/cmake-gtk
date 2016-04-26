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

static const string ON_VALUES[] = {"1", "ON", "TRUE", "Y", "YES"};

public bool is_on(string? val)
{
  if (val == null)
  {
    return false;
  }

  if (val.length > 4)
  {
    return false;
  }

  return val.up() in ON_VALUES;
}

//out string name,
//out CacheType type,
//out string value
bool parse_entry(string line, out CacheType type, out string name, out string value) throws RegexError
{
  // matches: key:type=value
  var reg = new Regex("^([^=:]*):([^=]*)=(.*[^\r\t ]|[\r\t ]*)[\r\t ]*$");

  // matches: "key":type=value
  var regQuoted = new Regex("^\"([^\"]*)\":([^=]*)=(.*[^\r\t ]|[\r\t ]*)[\r\t ]*$");

  // matches: key=value
  var reg2 = new Regex("^([^=]*)=(.*[^\r\t ]|[\r\t ]*)[\r\t ]*$");

  // matches: "key"=value
  var reg2Quoted = new Regex("^\"([^\"]*)\"=(.*[^\r\t ]|[\r\t ]*)[\r\t ]*$");

  bool success = false;
  MatchInfo match_info;

  if (regQuoted.match(line, 0, out match_info))
  {
    type = CacheType.parse(match_info.fetch(2));
    name = match_info.fetch(1);
    value = match_info.fetch(3);
    success = true;
  }
  else if (reg.match(line, 0, out match_info))
  {
    type = CacheType.parse(match_info.fetch(2));
    name = match_info.fetch(1);
    value = match_info.fetch(3);
    success = true;
  }
  else if (reg2Quoted.match(line, 0, out match_info))
  {
    type = CacheType.STRING;
    name = match_info.fetch(1);
    value = match_info.fetch(2);
    success = true;
  }
  else if (reg2.match(line, 0, out match_info))
  {
    type = CacheType.STRING;
    name = match_info.fetch(1);
    value = match_info.fetch(2);
    success = true;
  }

  // if value is enclosed in single quotes ('foo') then remove them
  // it is used to enclose trailing space or tab
  if (success && value.length >= 2 && value[0] == '\'' && value[value.length - 1] == '\'')
  {
    value = value.substring(1, value.length - 2);
  }

  if (type == CacheType.BOOL)
  {
    value = is_on(value) ? "ON" : "OFF";
  }

  return success;
}

void OutputKey(FileStream fout, string key)
{
  // support : in key name by double quoting
  if (key.has_prefix("//") || key.contains(":"))
  {
    fout.printf("\"%s\"", key);
  }
  else
  {
    fout.printf("%s", key);
  }
}

void OutputValue(FileStream fout, string value)
{
  // if value has trailing space or tab, enclose it in single quotes
  int size = value.length;
  if (size > 0 && (value[size - 1] == ' ' || value[size - 1] == '\t'))
  {
    fout.printf("'%s'", value);
  }
  else
  {
    fout.printf("%s", value);
  }
}

void OutputHelpString(FileStream fout, string helpString)
{
  int end = helpString.length;
  if (end == 0)
  {
    return;
  }

  int pos = 0;
  for (int i = 0; i <= end; ++i)
  {
    if (i == end || helpString[i] == '\n' || (i - pos >= 60 && helpString[i] == ' '))
    {
      fout.printf("//");
      if (helpString[pos] == '\n')
      {
        pos++;
        fout.printf("\\n");
      }

      fout.printf("%s\n", helpString.substring(pos, i - pos));
      pos = i;
    }
  }
}

void WritePropertyEntries(FileStream os, CacheEntry e)
{
  if (e.is_advanced)
  {
    OutputHelpString(os, "ADVANCED property for variable: " + e.name);
    OutputKey(os, e.name + "-ADVANCED");
    os.printf(":INTERNAL=1\n");
  }

  if (e.is_modified)
  {
    OutputHelpString(os, "MODIFIED property for variable: " + e.name);
    OutputKey(os, e.name + "-MODIFIED");
    os.printf(":INTERNAL=1\n");
  }

  if (e.strings != null)
  {
    OutputHelpString(os, "STRINGS property for variable: " + e.name);
    OutputKey(os, e.name + "-STRINGS");
    os.printf(":INTERNAL=");
    OutputValue(os, e.strings);
    os.printf("\n");
  }
}

public class Cache : Object, Gtk.TreeModel
{
  //! Load a cache for given makefile.  Loads from path/CMakeCache.txt.
  public bool load(string path) throws Error
  {
    string cacheFile = Path.build_filename(path, "CMakeCache.txt");

    // clear the old cache, if we are reading in internal values
    // this.clear();

    var fin = FileStream.open(cacheFile, "r");
    if (fin == null)
    {
      return false;
    }

    string? buffer;
    while ((buffer = fin.read_line()) != null)
    {
      buffer._chug();

      // skip blank lines and comment lines
      if (buffer[0] == '#' || buffer[0] == '\0')
      {
        continue;
      }

      string help = "";
      while (buffer[0] == '/' && buffer[1] == '/')
      {
        if (buffer[2] == '\\' && buffer[3] == 'n')
        {
          help += "\n";
          help += buffer.substring(4);
        }
        else
        {
          help += buffer.substring(2);
        }

        buffer = fin.read_line();
        if (buffer == null)
        {
          continue;
        }
      }

      string name;
      string value;
      CacheType type;

      if (CMake.parse_entry(buffer, out type, out name, out value))
      {
        if (type != CacheType.INTERNAL)
        {
          this.add_entry(type, name, value, help);
        }
        else if (this.read_property_entry(name, value) == false)
        {
          this.add_internal(name, value, help);
        }
      }
      else
      {
        error("Parse error in cache file '%s'. Offending entry: '%s'",
            cacheFile, buffer);
      }
    }

    // check to make sure the cache directory has not been moved
    string? creation_dir = this.lookup_value("CMAKE_CACHEFILE_DIR");
    if (creation_dir != null && creation_dir != path)
    {
      error("The current CMakeCache.txt directory '%s'" +
          " is different than the directory '%s'" +
          " where CMakeCache.txt was created. This may result " +
          "in binaries being created in the wrong place. If you " +
          "are not sure, reedit the CMakeCache.txt",
          path, creation_dir);
    }

    this.dirty = false;
    return true;
  }

  private bool read_property_entry(string name, string value)
  {
    if (name.has_suffix("-ADVANCED"))
    {
      int idx;
      string key = name.substring(0, name.length - 9);

      if (this.find(this.external, key, out idx))
      {
        unowned CacheEntry entry = this.external[idx];
        bool is_advanced = is_on(value);
        if (entry.is_advanced != is_advanced)
        {
          entry.is_advanced = is_advanced;

          var iter = Gtk.TreeIter();
          iter.stamp = stamp;
          iter.user_data = idx.to_pointer();
          this.row_changed(this.get_path(iter), iter);
        }
      }
      else
      {
        warning("ADVANCED property for unknown key '%s'\n", key);
      }

      return true;
    }

    if (name.has_suffix("-MODIFIED"))
    {
      int idx;
      string key = name.substring(0, name.length - 9);

      if (this.find(this.external, key, out idx))
      {
        this.external[idx].is_modified = is_on(value);
      }
      else
      {
        warning("MODIFIED property for unknown key '%s'\n", key);
      }

      return true;
    }

    if (name.has_suffix("-STRINGS"))
    {
      int idx;
      string key = name.substring(0, name.length - 8);

      if (this.find(this.external, key, out idx))
      {
        this.external[idx].strings = value;
      }
      else
      {
        warning("STRINGS property for unknown key '%s'\n", key);
      }

      return true;
    }

    return false;
  }

  //! Save cache for given makefile.  Saves to ouput path/CMakeCache.txt
  public bool save(string path)
  {
    if (!this.dirty)
    {
      return true;
    }

    string cacheFile = Path.build_filename(path, "CMakeCache.txt");
    var fout = FileStream.open(cacheFile, "w");
    if (fout == null)
    {
      error("Unable to open cache file '%s' for save.\n", cacheFile);
      // return false;
    }

    // Let us store the current working directory so that if somebody
    // Copies it, he will not be surprised
    this.add_internal("CMAKE_CACHEFILE_DIR", path,
      "This is the directory where this CMakeCache.txt was created");

    fout.printf("# This is the CMakeCache file.\n");
    fout.printf("# For build in directory: %s\n", path);
    fout.printf("# You can edit this file to change values found and used by cmake.\n");
    fout.printf("# If you do not want to change any of the values, simply exit the editor.\n");
    fout.printf("# If you do want to change a value, simply edit, save, and exit the editor.\n");
    fout.printf("# The syntax for the file is as follows:\n");
    fout.printf("# KEY:TYPE=VALUE\n");
    fout.printf("# KEY is the name of a variable in the cache.\n");
    fout.printf("# TYPE is a hint to GUIs for the type of VALUE, DO NOT EDIT TYPE!\n");
    fout.printf("# VALUE is the current value for the KEY.\n\n");

    fout.printf("########################\n");
    fout.printf("# EXTERNAL cache entries\n");
    fout.printf("########################\n");
    fout.printf("\n");

    this.external.foreach((entry) =>
    {
      if (entry.help != null)
      {
        OutputHelpString(fout, entry.help);
      }
      else
      {
        OutputHelpString(fout, "Missing description");
      }

      OutputKey(fout, entry.name);
      fout.printf(":%s=", entry.type.to_string());
      OutputValue(fout, entry.value);
      fout.printf("\n\n");
    });

    fout.printf("\n");
    fout.printf("########################\n");
    fout.printf("# INTERNAL cache entries\n");
    fout.printf("########################\n");
    fout.printf("\n");

    this.external.foreach((entry) =>
    {
      WritePropertyEntries(fout, entry);
    });

    this.internal.foreach((entry) =>
    {
      if (entry.help != null)
      {
        OutputHelpString(fout, entry.help);
      }

      OutputKey(fout, entry.name);
      fout.printf(":%s=", entry.type.to_string());
      OutputValue(fout, entry.value);
      fout.printf("\n");
    });

    return true;
  }

  //! Delete the cache given
  public void clear()
  {
    var path = new Gtk.TreePath.first();
    var length = this.external.length;
    for (int i = 0; i < length; ++i)
    {
      this.row_deleted(path);
    }

    this.external.length = 0;
    this.internal.length = 0;
  }

  //! Delete the cache given
  public void clear_cache(string path)
  {
    FileUtils.remove(Path.build_filename(path, "CMakeCache.txt"));
    DirUtils.remove(Path.build_filename(path, "CMakeFiles"));
    this.clear();
  }

  //! Add an entry into the cache
  public void add_entry(CacheType type, string name, string? value, string? help)
  {
    int idx;
    bool found = this.find(this.external, name, out idx);

    var iter = Gtk.TreeIter();
    iter.stamp = stamp;
    iter.user_data = idx.to_pointer();

    var path = this.get_path(iter);

    if (found)
    {
      unowned CacheEntry entry = this.external[idx];
      entry.type = type;
      entry.help = help;

      if (entry.value != value)
      {
        entry.value = value;
        entry.is_changed = true;
        this.row_changed(path, iter);
        this.dirty = true;
      }
    }
    else
    {
      this.external.insert(idx, new CacheEntry(type, name, value, help));
      this.row_inserted(path, iter);
      this.dirty = true;
    }
  }

  public void add_internal(string name, string? value, string? help)
  {
    int idx;
    if (this.find(this.internal, name, out idx))
    {
      unowned CacheEntry entry = this.internal[idx];
      entry.value = value;
      entry.help = help;
    }
    else
    {
      this.internal.insert(idx, new CacheEntry(CacheType.INTERNAL, name, value, help));
    }
  }

  //! Get a value from the cache given a key
  public string? lookup_value(string key)
  {
    int idx;

    if (this.find(this.external, key, out idx))
    {
      return this.external[idx].value;
    }

    if (this.find(this.internal, key, out idx))
    {
      return this.internal[idx].value;
    }

    return null;
  }

  // uses lower bound to search an Entry by name
  // return whether the Entry is an exact match
  // the index of the returned Entry is put into idx (useful for insert)
  private bool find(GenericArray<CacheEntry> table, string name, out int idx)
  {
    int begin = 0;
    int end = table.length;
    idx = (begin + end) / 2;

    while (begin < end)
    {
      int r = strcmp(name, table[idx].name);
      if (r == 0)
      {
        return true;
      }
      else if (r > 0)
      {
        begin = idx + 1;
      }
      else
      {
        end = idx;
      }

      idx = (begin + end) / 2;
    }

    return false;
  }

  public void remove_entry(Gtk.TreePath path)
  {
    this.external.remove_index(path.get_indices()[0]);
    this.row_deleted(path);
  }

  public void change_value(Gtk.TreePath path, Gtk.TreeIter iter, string value)
  {
    assert (iter.stamp == stamp);
    unowned CacheEntry entry = this.external[(int) (long) iter.user_data];
    if (entry.value != value)
    {
      entry.value = value;
      entry.is_changed = true;
      this.row_changed(path, iter);
      this.dirty = true;
    }
  }

  public unowned CacheEntry get_entry(Gtk.TreeIter iter)
  {
    assert (iter.stamp == stamp);
    return this.external[(int) (long) iter.user_data];
  }

// Gtk.TreeModel

  public Type get_column_type(int idx)
  {
    switch (idx)
    {
    case 0: // name
    case 1: // value
    case 2: // help
      return typeof(string);
    case 3:
      return typeof(int);
    default:
      assert_not_reached();
    }
  }

  public Gtk.TreeModelFlags get_flags()
  {
    return 0;
  }

  public bool get_iter(out Gtk.TreeIter iter, Gtk.TreePath path)
  {
    if (path.get_depth() != 1 || this.external.length == 0)
    {
      return invalid_iter(out iter);
    }

    iter = Gtk.TreeIter();
    iter.user_data = path.get_indices()[0].to_pointer();
    iter.stamp = this.stamp;
    return true;
  }

  public int get_n_columns()
  {
    return 4;
  }

  public Gtk.TreePath? get_path(Gtk.TreeIter iter)
  {
    assert (iter.stamp == stamp);
    return new Gtk.TreePath.from_indices((int) (long) iter.user_data);
  }

  public void get_value(Gtk.TreeIter iter, int column, out Value value)
  {
    assert (iter.stamp == stamp);

    unowned CacheEntry entry = this.external[(int) (long) iter.user_data];
    switch (column)
    {
      case 0:
        value = Value(typeof(string));
        value.set_string(entry.name);
        break;

      case 1:
        value = Value(typeof(string));
        value.set_string(entry.value);
        break;

      case 2:
        value = Value(typeof(string));
        value.set_string(entry.help);
        break;

      case 3:
        value = Value(typeof(int));
        value.set_int(entry.is_changed ? Pango.Weight.BOLD : Pango.Weight.NORMAL);
        break;

      default:
        value = Value(Type.INVALID);
        break;
    }
  }

  public bool iter_children(out Gtk.TreeIter iter, Gtk.TreeIter? parent)
  {
    assert (parent == null || parent.stamp == stamp);
    // Only used for trees
    return invalid_iter(out iter);
  }

  public bool iter_has_child(Gtk.TreeIter iter)
  {
    assert (iter.stamp == stamp);
    // Only used for trees
    return false;
  }

  public int iter_n_children(Gtk.TreeIter? iter)
  {
    assert (iter == null || iter.stamp == stamp);
    return (iter == null) ? this.external.length : 0;

    // TODO: return number of !internal
  }

  public bool iter_next(ref Gtk.TreeIter iter)
  {
    assert (iter.stamp == stamp);

    int pos = ((int) (long) iter.user_data) + 1;
    if (pos >= this.external.length)
    {
      return false;
    }

    iter.user_data = pos.to_pointer();
    return true;
  }

  public bool iter_nth_child(out Gtk.TreeIter iter, Gtk.TreeIter? parent, int n)
  {
    assert (parent == null || parent.stamp == stamp);

    if (parent == null && n < this.external.length)
    {
      iter = Gtk.TreeIter();
      iter.stamp = stamp;
      iter.user_data = n.to_pointer();
      return true;
    }

    // Only used for trees
    return invalid_iter(out iter);
  }

  public bool iter_parent(out Gtk.TreeIter iter, Gtk.TreeIter child)
  {
    assert (child.stamp == stamp);
    // Only used for trees
    return invalid_iter(out iter);
  }

  private bool invalid_iter(out Gtk.TreeIter iter)
  {
    iter = Gtk.TreeIter();
    iter.stamp = -1;
    return false;
  }

// members

  private GenericArray<CacheEntry> external = new GenericArray<CacheEntry>();
  private GenericArray<CacheEntry> internal = new GenericArray<CacheEntry>();
  private int stamp = 0;
  private bool dirty = false;
}

} // namespace CMake
