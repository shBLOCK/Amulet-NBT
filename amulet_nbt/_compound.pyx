## This file is generated by tempita. Do not modify this file directly or your changes will get overwritten.
## To edit this file edit the template in template/src

from io import BytesIO
import re
from typing import Iterator, Dict
from copy import copy, deepcopy
from collections.abc import MutableMapping
import sys
import warnings

from . import __major__
from ._value cimport AbstractBaseTag, AbstractBaseMutableTag
from ._const cimport ID_END, ID_COMPOUND, CommaSpace, CommaNewline
from ._util cimport write_byte, BufferContext, read_byte, read_string
if __major__ <= 2:
    from ._util import primitive_conversion
from ._load_nbt cimport load_payload
from ._dtype import AnyNBT, DecoderType, EncoderType

NON_QUOTED_KEY = re.compile('[A-Za-z0-9._+-]+')


cdef inline CyCompoundTag read_compound_tag(BufferContext buffer, bint little_endian, string_decoder: DecoderType):
    cdef CyCompoundTag tag = CompoundTag()
    cdef char tag_type
    cdef str name
    cdef AbstractBaseTag child_tag

    while True:
        tag_type = read_byte(buffer)
        if tag_type == ID_END:
            break
        else:
            name = read_string(buffer, little_endian, string_decoder)
            child_tag = load_payload(buffer, tag_type, little_endian, string_decoder)
            tag[name] = child_tag
    return tag


cdef inline void _check_dict(dict value) except *:
    cdef str key
    cdef AbstractBaseTag val
    for key, val in value.items():
        if key is None or val is None:
            raise TypeError()


cdef class CyCompoundTag(AbstractBaseMutableTag):
    """
    This class behaves like a python dictionary.
    All keys must be strings and all values must be NBT data types.
    """
    tag_id = ID_COMPOUND

    def __init__(CyCompoundTag self, object value = (), **kwargs):
        cdef dict dict_value = dict(value, **kwargs)
        _check_dict(dict_value)
        self.value_ = dict_value

    def __str__(CyCompoundTag self):
        return str(self.value_)

    def __eq__(CyCompoundTag self, other):
        cdef CyCompoundTag other_
        if isinstance(other, CyCompoundTag):
            other_ = other
            return self.value_ == other_.value_
        elif __major__ <= 2:
            warnings.warn("NBT comparison operator (a == b) will only return True between classes of the same type.", FutureWarning)
            return self.value_ == primitive_conversion(other)
        return NotImplemented

    def __reduce__(CyCompoundTag self):
        return self.__class__, (self.value_,)

    def __deepcopy__(CyCompoundTag self, memo=None):
        return self.__class__(deepcopy(self.value_, memo=memo))

    def __copy__(CyCompoundTag self):
        return self.__class__(self.value_)

    @property
    def py_dict(CyCompoundTag self) -> Dict[str, AnyNBT]:
        """
        A python dictionary representation of the class.
        The returned list is a shallow copy of the class, meaning changes will not mirror the instance.
        Use the public API to modify the internal data.
        """
        return copy(self.value_)

    @property
    def py_data(self):
        return self.py_dict

    @staticmethod
    def fromkeys(object keys, AbstractBaseTag value=None):
        return CompoundTag(dict.fromkeys(keys, value))
    fromkeys.__func__.__doc__ = dict.fromkeys.__doc__

    cdef str _to_snbt(CyCompoundTag self):
        cdef str name
        cdef AbstractBaseTag elem
        cdef list tags = []
        for name in sorted(self.value_, key=lambda k: (k.lower(), k.swapcase())):
            elem = self.value_[name]
            if NON_QUOTED_KEY.fullmatch(name) is None:
                tags.append(f'"{name}": {elem.to_snbt()}')
            else:
                tags.append(f'{name}: {elem.to_snbt()}')
        return f"{{{CommaSpace.join(tags)}}}"

    cdef str _pretty_to_snbt(CyCompoundTag self, str indent_chr, int indent_count=0, bint leading_indent=True):
        cdef str name
        cdef AbstractBaseTag elem
        cdef list tags = []
        for name in sorted(self.value_, key=lambda k: (k.lower(), k.swapcase())):
            elem = self.value_[name]
            tags.append(f'{indent_chr * (indent_count + 1)}"{name}": {elem._pretty_to_snbt(indent_chr, indent_count + 1, False)}')
        if tags:
            return f"{indent_chr * indent_count * leading_indent}{{\n{CommaNewline.join(tags)}\n{indent_chr * indent_count}}}"
        else:
            return f"{indent_chr * indent_count * leading_indent}{{}}"

    cdef void write_payload(
        CyCompoundTag self,
        object buffer: BytesIO,
        bint little_endian,
        string_encoder: EncoderType
    ) except *:
        cdef str key
        cdef AbstractBaseTag tag

        for key, tag in self.value_.items():
            tag.write_tag(buffer, key, little_endian, string_encoder)
        write_byte(ID_END, buffer)

    def __repr__(CyCompoundTag self):
        return f"{self.__class__.__name__}({repr(self.value_)})"

    def __getitem__(CyCompoundTag self, str key not None) -> AbstractBaseTag:
        return self.value_[key]

    def __setitem__(CyCompoundTag self, str key not None, AbstractBaseTag value not None):
        self.value_[key] = value

    def __delitem__(CyCompoundTag self, str key not None):
        self.value_.__delitem__(key)

    def __iter__(CyCompoundTag self) -> Iterator[str]:
        yield from self.value_

    def __len__(CyCompoundTag self) -> int:
        return self.value_.__len__()


if sys.version_info >= (3, 9):
    class CompoundTag(CyCompoundTag, MutableMapping[str, AnyNBT]):
        pass

else:
    class CompoundTag(CyCompoundTag, MutableMapping):
        pass
