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

[Compact]
public class CacheEntry
{
  public CacheEntry(CacheType ctype, string name, string? value, string? help)
  {
    this.name = name;
    this.value = value;
    this.type = ctype;
    this.help = help;
  }

  public string name;
  public string value;

  public CacheType type;

  // hidden per default
  public bool is_advanced = false;

  // ???
  public bool is_modified = false;

  // value was modified, show in bold
  public bool is_changed = false;

  // dropdown values, separated by ;
  public string? strings = null;

  // string to show as tooltip
  public string? help;
}

} // namespace CMake
