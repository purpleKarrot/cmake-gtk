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

public class Wrapper : Object
{
  public string source_dir { get; set; }
  public string binary_dir { get; set; }

  public string generator { get; set; }

  // Do we want debug output during the cmake run.
  public bool debug_output { get; set; }

  public bool warn_unitialized { get; set; }

  public bool warn_unused { get; set; }

  public bool dev_warnings { get; set; }


  public signal void stdout_message(string msg);
  public signal void stderr_message(string msg);

  public signal void progress(string msg, float percent);

  public delegate void ProgressCallback(string msg, float progress);
  public ProgressCallback progress_callback { get; set; }

  public string[] available_generators()
  {
    string[] generators = {};

    string standard_output;
    string[] argv = {cmake_cmd, "-E", "capabilities"};
    Process.spawn_sync(null, argv, null, 0, null, out standard_output);

    var parser = new Json.Parser();
    parser.load_from_data(standard_output, -1);

    var root_object = parser.get_root().get_object();
    var gen_array = root_object.get_array_member("generators");

    foreach (var gen in gen_array.get_elements())
    {
      var generator = gen.get_object();
      generators += generator.get_string_member("name");
    }

    return generators;
  }

  // run the configure step
  public int configure()
  {
    string[] argv = {cmake_cmd, "."};

    Pid child_pid;
    int standard_output;
    int standard_error;

    Process.spawn_async_with_pipes(binary_dir, argv, null,
        SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid,
        null, out standard_output, out standard_error);

    // stdout:
    IOChannel output = new IOChannel.unix_new(standard_output);
    output.add_watch(IOCondition.IN | IOCondition.HUP, process_output);

    // stderr:
    IOChannel error = new IOChannel.unix_new(standard_error);
    error.add_watch(IOCondition.IN | IOCondition.HUP, process_error);

    ChildWatch.add(child_pid, (pid, status) =>
    {
      Process.close_pid(pid);
    });

    return 0;
  }

  // run the build step
  public int build()
  {
    string[] argv = {cmake_cmd, "--build", "."};

    Pid child_pid;
    int standard_output;
    int standard_error;

    Process.spawn_async_with_pipes(binary_dir, argv, null,
        SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid,
        null, out standard_output, out standard_error);

    // stdout:
    IOChannel output = new IOChannel.unix_new(standard_output);
    output.add_watch(IOCondition.IN | IOCondition.HUP, process_output);

    // stderr:
    IOChannel error = new IOChannel.unix_new(standard_error);
    error.add_watch(IOCondition.IN | IOCondition.HUP, process_error);

    ChildWatch.add(child_pid, (pid, status) =>
    {
      Process.close_pid(pid);
    });

    return 0;
  }

  private bool process_output(IOChannel channel, IOCondition condition)
  {
    if (condition == IOCondition.HUP)
    {
      return false;
    }

    string line;
    channel.read_line(out line, null, null);
    stdout_message(line);
    return true;
  }

  private bool process_error(IOChannel channel, IOCondition condition)
  {
    if (condition == IOCondition.HUP)
    {
      return false;
    }

    string line;
    channel.read_line(out line, null, null);
    stderr_message(line);
    return true;
  }

  private string? cmake_cmd = Environment.find_program_in_path("cmake");
}

} // namespace CMake
