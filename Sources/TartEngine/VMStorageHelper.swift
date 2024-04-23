import Foundation

package class VMStorageHelper {
  package static func open(_ name: String, config: any ConfigProtocol) throws -> VMDirectory {
    try missingVMWrap(name) {
      if let remoteName = try? RemoteName(name) {
        return try VMStorageOCI(config: config).open(remoteName)
      } else {
        return try VMStorageLocal(config: config).open(name)
      }
    }
  }

  package static func delete(_ name: String, config: any ConfigProtocol) throws {
    try missingVMWrap(name) {
      if let remoteName = try? RemoteName(name) {
        try VMStorageOCI(config: config).delete(remoteName)
      } else {
        try VMStorageLocal(config: config).delete(name)
      }
    }
  }

  private static func missingVMWrap<R: Any>(_ name: String, closure: () throws -> R) throws -> R {
    do {
      return try closure()
    } catch {
      if error.isFileNotFound() {
        throw RuntimeError.VMDoesNotExist(name: name)
      }

      throw error
    }
  }
}

extension NSError {
  func isFileNotFound() -> Bool {
    return self.code == NSFileNoSuchFileError || self.code == NSFileReadNoSuchFileError
  }
}

extension Error {
  package func isFileNotFound() -> Bool {
    (self as NSError).isFileNotFound() || (self as NSError).underlyingErrors.contains(where: { $0.isFileNotFound() })
  }
}

package enum RuntimeError : Error {
  case VMConfigurationError(_ message: String)
  case VMDoesNotExist(name: String)
  case VMMissingFiles(_ message: String)
  case VMIsRunning(_ name: String)
  case VMNotRunning(_ name: String)
  case VMAlreadyRunning(_ message: String)
  case NoIPAddressFound(_ message: String)
  case DiskAlreadyInUse(_ message: String)
  case InvalidDiskSize(_ message: String)
  case FailedToUpdateAccessDate(_ message: String)
  case PIDLockFailed(_ message: String)
  case FailedToParseRemoteName(_ message: String)
  case VMTerminationFailed(_ message: String)
  case InvalidCredentials(_ message: String)
  case VMDirectoryAlreadyInitialized(_ message: String)
  case ExportFailed(_ message: String)
  case ImportFailed(_ message: String)
  case SoftnetFailed(_ message: String)
  case OCIStorageError(_ message: String)
  case OCIUnsupportedDiskFormat(_ format: String)
  case SuspendFailed(_ message: String)
}

package protocol HasExitCode {
  var exitCode: Int32 { get }
}

extension RuntimeError : CustomStringConvertible {
  public var description: String {
    switch self {
    case .VMConfigurationError(let message):
      return message
    case .VMDoesNotExist(let name):
      return "the specified VM \"\(name)\" does not exist"
    case .VMMissingFiles(let message):
      return message
    case .VMIsRunning(let name):
      return "VM \"\(name)\" is running"
    case .VMNotRunning(let name):
      return "VM \"\(name)\" is not running"
    case .VMAlreadyRunning(let message):
      return message
    case .NoIPAddressFound(let message):
      return message
    case .DiskAlreadyInUse(let message):
      return message
    case .InvalidDiskSize(let message):
      return message
    case .FailedToUpdateAccessDate(let message):
      return message
    case .PIDLockFailed(let message):
      return message
    case .FailedToParseRemoteName(let cause):
      return "failed to parse remote name: \(cause)"
    case .VMTerminationFailed(let message):
      return message
    case .InvalidCredentials(let message):
      return message
    case .VMDirectoryAlreadyInitialized(let message):
      return message
    case .ExportFailed(let message):
      return "VM export failed: \(message)"
    case .ImportFailed(let message):
      return "VM import failed: \(message)"
    case .SoftnetFailed(let message):
      return "Softnet failed: \(message)"
    case .OCIStorageError(let message):
      return "OCI storage error: \(message)"
    case .OCIUnsupportedDiskFormat(let format):
      return "OCI disk format \(format) is not supported by this version of Tart"
    case .SuspendFailed(let message):
      return "Failed to suspend the VM: \(message)"
    }
  }
}

extension RuntimeError : HasExitCode {
  package var exitCode: Int32 {
    switch self {
    case .VMDoesNotExist:
      return 2
    case .VMNotRunning:
      return 2
    case .VMAlreadyRunning:
      return 2
    default:
      return 1
    }
  }
}

// Customize error description for Sentry[1]
//
// [1]: https://docs.sentry.io/platforms/apple/guides/ios/usage/#customizing-error-descriptions
extension RuntimeError : CustomNSError {
  package var errorUserInfo: [String : Any] {
    [
      NSDebugDescriptionErrorKey: description,
    ]
  }
}