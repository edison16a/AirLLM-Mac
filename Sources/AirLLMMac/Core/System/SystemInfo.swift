import Foundation

/// The parts of this Mac that decide which models can run: memory, free disk and chip.
struct SystemInfo: Equatable {
    var ramGB: Double
    var freeDiskGB: Double
    var chipName: String

    static var current: SystemInfo {
        SystemInfo(ramGB: Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824,
                   freeDiskGB: freeDisk(),
                   chipName: sysctlString("machdep.cpu.brand_string") ?? "Apple silicon")
    }

    static var isAppleSilicon: Bool {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctlbyname("hw.optional.arm64", &value, &size, nil, 0)
        return value == 1
    }

    /// "Important usage" capacity counts space macOS would free up for a big download,
    /// which matches what a model download can actually use.
    private static func freeDisk() -> Double {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage.map { Double($0) / 1_073_741_824 } ?? 0
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &buffer, &size, nil, 0)
        let s = String(cString: buffer)
        return s.isEmpty ? nil : s
    }
}
