import os
from typing import Callable, TypeVar, Sequence, TypeAlias
import unittest
from amulet_nbt import CompoundTag, read_nbt, read_snbt, NamedTag, AbstractBaseTag

DATA_DIR = os.path.join(os.path.dirname(__file__), "src")

EncodedT = TypeVar("EncodedT")
# Group name, decoder, encoder
GroupType: TypeAlias = tuple[
    str, Callable[[EncodedT], NamedTag], Callable[[NamedTag], EncodedT]
]


class FileNBTTests(unittest.TestCase):
    def setUp(self) -> None:
        self.maxDiff = None

        def _open_snbt(path_: str) -> NamedTag:
            if os.path.isfile(path_):
                with open(path_, encoding="utf-8") as f_:
                    snbt = f_.read()
            else:
                snbt = path_
            return NamedTag(read_snbt(snbt))

        self._groups: Sequence[GroupType] = (
            (
                "big_endian_compressed_nbt",
                lambda path_: read_nbt(path_, compressed=True, little_endian=False),
                lambda obj_: obj_.save_to(compressed=True, little_endian=False),
            ),
            (
                "big_endian_nbt",
                lambda path_: read_nbt(path_, compressed=False, little_endian=False),
                lambda obj_: obj_.save_to(compressed=False, little_endian=False),
            ),
            (
                "little_endian_nbt",
                lambda path_: read_nbt(path_, compressed=False, little_endian=True),
                lambda obj_: obj_.save_to(compressed=False, little_endian=True),
            ),
            (
                "snbt",
                _open_snbt,
                lambda obj_: obj_.tag.to_snbt("    "),
            ),
        )

    def test_load_nbt(self) -> None:
        # read in all the data
        group_data: dict[str, dict[str, NamedTag]] = {}
        for group1, load1, _ in self._groups:
            for path1 in os.listdir(os.path.join(DATA_DIR, group1)):
                name = os.path.splitext(path1)[0]
                try:
                    data = load1(os.path.join(DATA_DIR, group1, path1))
                except Exception as e_:
                    print(group1, path1)
                    raise e_
                self.assertIsInstance(data, NamedTag)
                self.assertIsInstance(data.tag, CompoundTag)
                group_data.setdefault(name, {})[group1] = data

        # compare to all the other loaded data
        for name, name_data in group_data.items():
            for group1, _, _ in self._groups:
                for group2, _, _ in self._groups:
                    if group1 == "snbt" or group2 == "snbt":
                        self.assertEqual(
                            name_data[group1].tag,
                            name_data[group2].tag,
                            f"{group1} {group2} {name}",
                        )
                    else:
                        self.assertEqual(
                            name_data[group1],
                            name_data[group2],
                            f"{group1} {group2} {name}",
                        )

        for name, name_data in group_data.items():
            for group1, load, save in self._groups:
                data = name_data[group1]
                self.assertEqual(data, load(save(data)), f"{group1} {name}")


if __name__ == "__main__":
    unittest.main()
