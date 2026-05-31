import ArgumentParser
import Darwin
import Foundation

/// Returns the option value if provided,
/// reads stdin if it's not a TTY,
/// or throws if stdin is a TTY.
func readBody(_ option: String?) throws -> String {
  if let body = option { return body }
  if isatty(STDIN_FILENO) != 0 {
    fputs("\(CLILocalized("card.create.error.tty"))\n", stderr)
    throw ExitCode.failure
  }
  return String(bytes: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
}
