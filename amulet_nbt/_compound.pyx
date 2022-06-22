## This file is generated by tempita. Do not modify this file directly or your changes will get overwritten.
## To edit this file edit the template in template/src

from io import BytesIO
import re
from typing import Iterator, Dict, Type, TypeVar
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
from ._int cimport (
    ByteTag,
    ShortTag,
    IntTag,
    LongTag,
)
from ._float cimport (
    FloatTag,
    DoubleTag,
)
from ._array cimport (
    ByteArrayTag,
    IntArrayTag,
    LongArrayTag,
)
from ._string cimport StringTag
from ._list cimport CyListTag

NON_QUOTED_KEY = re.compile('[A-Za-z0-9._+-]+')

T = TypeVar("T")
Error = object()


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
        """
        A python representation of the class. Note that the return type is undefined and may change in the future.
        You would be better off using the py_{type} or np_array properties if you require a fixed type.
        This is here for convenience to get a python representation under the same property name.
        """
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

    cpdef ByteTag get_byte(self, str key, ByteTag default=None):
        """Get the tag stored in key if it is a ByteTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The ByteTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a ByteTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, ByteTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type ByteTag but got {type(tag)}")
        else:
            return default

    cpdef ByteTag setdefault_byte(self, str key, ByteTag default=None):
        """Populate key if not defined or value is not ByteTag. Return the value stored.
    
        If default is a ByteTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The ByteTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], ByteTag):
            val = self[key] = ByteTag() if default is None else default
        return val

    cpdef ShortTag get_short(self, str key, ShortTag default=None):
        """Get the tag stored in key if it is a ShortTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The ShortTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a ShortTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, ShortTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type ShortTag but got {type(tag)}")
        else:
            return default

    cpdef ShortTag setdefault_short(self, str key, ShortTag default=None):
        """Populate key if not defined or value is not ShortTag. Return the value stored.
    
        If default is a ShortTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The ShortTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], ShortTag):
            val = self[key] = ShortTag() if default is None else default
        return val

    cpdef IntTag get_int(self, str key, IntTag default=None):
        """Get the tag stored in key if it is a IntTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The IntTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a IntTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, IntTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type IntTag but got {type(tag)}")
        else:
            return default

    cpdef IntTag setdefault_int(self, str key, IntTag default=None):
        """Populate key if not defined or value is not IntTag. Return the value stored.
    
        If default is a IntTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The IntTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], IntTag):
            val = self[key] = IntTag() if default is None else default
        return val

    cpdef LongTag get_long(self, str key, LongTag default=None):
        """Get the tag stored in key if it is a LongTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The LongTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a LongTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, LongTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type LongTag but got {type(tag)}")
        else:
            return default

    cpdef LongTag setdefault_long(self, str key, LongTag default=None):
        """Populate key if not defined or value is not LongTag. Return the value stored.
    
        If default is a LongTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The LongTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], LongTag):
            val = self[key] = LongTag() if default is None else default
        return val

    cpdef FloatTag get_float(self, str key, FloatTag default=None):
        """Get the tag stored in key if it is a FloatTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The FloatTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a FloatTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, FloatTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type FloatTag but got {type(tag)}")
        else:
            return default

    cpdef FloatTag setdefault_float(self, str key, FloatTag default=None):
        """Populate key if not defined or value is not FloatTag. Return the value stored.
    
        If default is a FloatTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The FloatTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], FloatTag):
            val = self[key] = FloatTag() if default is None else default
        return val

    cpdef DoubleTag get_double(self, str key, DoubleTag default=None):
        """Get the tag stored in key if it is a DoubleTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The DoubleTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a DoubleTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, DoubleTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type DoubleTag but got {type(tag)}")
        else:
            return default

    cpdef DoubleTag setdefault_double(self, str key, DoubleTag default=None):
        """Populate key if not defined or value is not DoubleTag. Return the value stored.
    
        If default is a DoubleTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The DoubleTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], DoubleTag):
            val = self[key] = DoubleTag() if default is None else default
        return val

    cpdef StringTag get_string(self, str key, StringTag default=None):
        """Get the tag stored in key if it is a StringTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The StringTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a StringTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, StringTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type StringTag but got {type(tag)}")
        else:
            return default

    cpdef StringTag setdefault_string(self, str key, StringTag default=None):
        """Populate key if not defined or value is not StringTag. Return the value stored.
    
        If default is a StringTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The StringTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], StringTag):
            val = self[key] = StringTag() if default is None else default
        return val

    cpdef CyListTag get_list(self, str key, CyListTag default=None):
        """Get the tag stored in key if it is a CyListTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The CyListTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a CyListTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, CyListTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type CyListTag but got {type(tag)}")
        else:
            return default

    cpdef CyListTag setdefault_list(self, str key, CyListTag default=None):
        """Populate key if not defined or value is not CyListTag. Return the value stored.
    
        If default is a CyListTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The CyListTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], CyListTag):
            val = self[key] = CyListTag() if default is None else default
        return val

    cpdef CyCompoundTag get_compound(self, str key, CyCompoundTag default=None):
        """Get the tag stored in key if it is a CyCompoundTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The CyCompoundTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a CyCompoundTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, CyCompoundTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type CyCompoundTag but got {type(tag)}")
        else:
            return default

    cpdef CyCompoundTag setdefault_compound(self, str key, CyCompoundTag default=None):
        """Populate key if not defined or value is not CyCompoundTag. Return the value stored.
    
        If default is a CyCompoundTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The CyCompoundTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], CyCompoundTag):
            val = self[key] = CyCompoundTag() if default is None else default
        return val

    cpdef ByteArrayTag get_byte_array(self, str key, ByteArrayTag default=None):
        """Get the tag stored in key if it is a ByteArrayTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The ByteArrayTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a ByteArrayTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, ByteArrayTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type ByteArrayTag but got {type(tag)}")
        else:
            return default

    cpdef ByteArrayTag setdefault_byte_array(self, str key, ByteArrayTag default=None):
        """Populate key if not defined or value is not ByteArrayTag. Return the value stored.
    
        If default is a ByteArrayTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The ByteArrayTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], ByteArrayTag):
            val = self[key] = ByteArrayTag() if default is None else default
        return val

    cpdef IntArrayTag get_int_array(self, str key, IntArrayTag default=None):
        """Get the tag stored in key if it is a IntArrayTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The IntArrayTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a IntArrayTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, IntArrayTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type IntArrayTag but got {type(tag)}")
        else:
            return default

    cpdef IntArrayTag setdefault_int_array(self, str key, IntArrayTag default=None):
        """Populate key if not defined or value is not IntArrayTag. Return the value stored.
    
        If default is a IntArrayTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The IntArrayTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], IntArrayTag):
            val = self[key] = IntArrayTag() if default is None else default
        return val

    cpdef LongArrayTag get_long_array(self, str key, LongArrayTag default=None):
        """Get the tag stored in key if it is a LongArrayTag.
    
        :param key: The key to get
        :param default: The value to return if the key does not exist or the type is wrong. If not defined errors are raised.
        :return: The LongArrayTag.
        :raises: KeyError if the key does not exist
        :raises: TypeError if the stored type is not a LongArrayTag
        """
        if key not in self:
            if default is Error:
                raise KeyError(key)
            else:
                return default

        tag = self[key]
        if isinstance(tag, LongArrayTag):
            return tag
        elif default is Error:
            raise TypeError(f"Expected tag to be of type LongArrayTag but got {type(tag)}")
        else:
            return default

    cpdef LongArrayTag setdefault_long_array(self, str key, LongArrayTag default=None):
        """Populate key if not defined or value is not LongArrayTag. Return the value stored.
    
        If default is a LongArrayTag then it will be stored under key else a default instance will be created.
        :param key: The key to populate and get
        :param default: The default value to use
        :return: The LongArrayTag stored in key
        :raises: TypeError if the input types are incorrect
        """
        val = self[key] if key in self else None
        if not isinstance(self[key], LongArrayTag):
            val = self[key] = LongArrayTag() if default is None else default
        return val


if sys.version_info >= (3, 9):
    class CompoundTag(CyCompoundTag, MutableMapping[str, AnyNBT]):
        pass

else:
    class CompoundTag(CyCompoundTag, MutableMapping):
        pass
