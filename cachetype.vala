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

public enum CacheType
{
  BOOL = 0,
  PATH,
  FILEPATH,
  STRING,
  STATIC,
  INTERNAL;

  public string to_string()
  {
    switch (this)
    {
    case BOOL:
      return "BOOL";

    case PATH:
      return "PATH";

    case FILEPATH:
      return "FILEPATH";

    case STRING:
      return "STRING";

    case STATIC:
      return "STATIC";

    case INTERNAL:
      return "INTERNAL";

    default:
      assert_not_reached();
    }
  }

  public static CacheType parse(string str)
  {
    switch (str)
    {
    case "BOOL":
      return BOOL;

    case "PATH":
      return PATH;

    case "FILEPATH":
      return FILEPATH;

    case "STRING":
      return STRING;

    case "STATIC":
      return STATIC;

    case "INTERNAL":
      return INTERNAL;

    default:
      error("invalid CACHE type '%s'\n", str);
      assert_not_reached();
    }
  }
}

} // namespace CMake
