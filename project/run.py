from pathlib import Path
from vunit import VUnit

VU = VUnit.from_argv()
VU.add_osvvm()
VU.add_verification_components()
VU.enable_location_preprocessing()

SRC_PATH = Path(__file__).parent / "bus"

VU.add_library("bus_lib").add_source_files(SRC_PATH / "*.vhd")
VU.add_library("tb_bus_lib").add_source_files(SRC_PATH / "test" / "*.vhd")

VU.main()
