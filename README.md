<h1 align="center">xilinx-boot-loader</h1>

<p align="center">
  <code>C++23</code> &middot; <code>idax-powered</code> &middot; <code>Decoupled Engine</code> &middot; <code>Zero-Copy Extraction</code>
</p>

---

<h5 align="center">
 xilinx-boot-loader is an IDA Pro module for parsing Xilinx boot firmware.<br/>
 It dynamically maps monolithic BOOT.BIN and PDI files into discrete memory segments,<br/>
 isolating multi-stage bootloaders, programmable logic, and firmware partitions.<br/>
<br/>
 Nested headers are traversed. Embedded segment names are extracted.<br/>
 Hardware-specific load addresses are routed natively to IDA's analysis engine.<br/>
 Automatically recovering the entire execution chain from Zynq 7000 to Versal adaptive SoCs.
</h5>

## Features

The loader automatically detects and unpacks multiple generations of Xilinx System-on-Chip firmware, completely abstracting the complex header indirection into clear, strictly bounded IDA memory segments.

- **Dynamic Format Detection:** Reliably targets and discriminates architectures via `XNLX` (`0x584C4E58`) signatures and specific width-detection bytes mapped across both legacy `.bin` and modern `.pdi` locations.
- **Deep Partition Mapping:** Recursively walks the nested Image Header Tables. It maps out First Stage Boot Loaders (FSBL), Platform Loader and Managers (PLM), Platform Management Controller (PMC) data, and unencrypted hardware partitions without massive IDB bloat.
- **String Table Unpacking:** Recovers packed big-endian segment names natively encoded in the firmware (e.g. `u_boot.elf`, `Zynq7007_miner.bit`) and assigns them directly to IDA segments for unmatched clarity.
- **Concurrent Entry Points:** Automatically derives exact execution addresses for all viable binary partitions and pushes them into IDA's entry table, guaranteeing comprehensive multi-stage auto-analysis.
- **Headless & Decoupled Engine:** The structure-parsing core (`src/parser.cpp`) runs entirely independent of the IDA SDK via an abstract `Reader` interface. It guarantees high-performance headless batch processing (like `idump`) and enables extensive raw-buffer unit testing.

## Supported Architectures

* **Zynq 7000 SoC** (`BOOT.BIN`) - Support for legacy sequential partition header arrays
* **Zynq UltraScale+ MPSoC** (`BOOT.BIN`) - Full pointer-linked nested boot hierarchy parsing
* **Versal Adaptive SoC** (`.pdi`) - High-level Meta-Header parsing & PMC load routing
* **Spartan UltraScale+** (`.pdi`)
* **Versal AI Edge Series Gen 2 / Versal Prime Series Gen 2** (`.pdi`)

## The Decoupled Architecture

Unlike traditional IDA loaders that deeply entangle internal SDK logic (`qlread`, `qoff64_t`) directly into format parsing, `xilinx-boot-loader` strictly isolates the domain constraints.

```cpp
// 1. A pure abstract parsing boundary. Zero IDA SDK leakage.
struct Reader {
    virtual bool read_bytes(uint64_t offset, void* buffer, size_t size) = 0;
};

// 2. The core format engine returns a well-formed value object
xilinx::ParsedImage img = xilinx::parse_image(reader);

// 3. The thin idax Loader class merely executes the mapping commands
for (const auto& part : img.partitions) {
    ida::segment::create(part.load_address, part.load_address + part.data_size, part.name, ...);
    ida::loader::file_to_database(file.handle(), part.data_offset, part.load_address, part.data_size, true);
    ida::entry::add(part.exec_address, part.name + "_entry");
}
```

This strict architectural separation permits massive performance wins, complete fuzzing capability, and enables a highly reliable `make test` pipeline that verifies tricky Xilinx pointer boundary math without ever booting the IDA runtime.

## Building

### Requirements
- CMake 3.27+
- C++23 Compiler (Clang 16+ / GCC 13+ / MSVC 19.38+)
- IDA Pro 9.3 SDK
- `idax` C++23 SDK wrapper (Automatically fetched via CMake)

### Build Instructions

The project uses CMakePresets wrapped by a simple Makefile for human-friendly execution:

```bash
# Build the highly optimized release loader
make loader

# Run the headless C++ parsing unit tests
make test
```

### Installation

1. Copy the compiled artifact (`build-release-optimized/zynqmp_boot_image_loader.dylib` on macOS, `.dll` on Windows, or `.so` on Linux) directly into your IDA installation's `loaders/` directory.
2. Open IDA and drag-and-drop a `BOOT.BIN` or `.pdi` firmware file.
3. The format detection will identify the exact Xilinx variant. Select it and press OK.
4. Let the loader orchestrate the specific hardware layout and begin your analysis.

## License

Available under the MIT License.
