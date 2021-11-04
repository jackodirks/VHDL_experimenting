from pathlib import Path
from vunit import VUnit

VU = VUnit.from_argv()
VU.add_osvvm()
VU.add_verification_components()
VU.enable_location_preprocessing()

SRC_PATH = Path(__file__).parent

src_library = VU.add_library("src")
tb_library = VU.add_library("tb")

src_library.add_source_files(SRC_PATH / "bus" / "*.vhd")
tb_library.add_source_files(SRC_PATH / "bus" / "test" / "*.vhd")

src_library.add_source_files(SRC_PATH / "deppSlave" / "*.vhd")
tb_library.add_source_files(SRC_PATH / "deppSlave" / "test" / "*.vhd")

VU.main()
