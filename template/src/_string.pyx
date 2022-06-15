## This file is generated by tempita. Do not modify this file directly or your changes will get overwritten.
## To edit this file edit the template in template/src

from io import BytesIO
from copy import deepcopy

from ._value cimport AbstractBaseImmutableTag
from ._const cimport ID_STRING
from ._util cimport write_string, read_string, BufferContext
from ._dtype import EncoderType
{{py:from template import include}}


cdef inline escape(str string):
    return string.replace('\\', '\\\\').replace('"', '\\"')


cdef inline StringTag read_string_tag(BufferContext buffer, bint little_endian, string_decoder: DecoderType):
    cdef StringTag tag = StringTag.__new__(StringTag)
    tag.value_ = read_string(buffer, little_endian, string_decoder)
    return tag


cdef class StringTag(AbstractBaseImmutableTag):
    """A class that behaves like a string."""
    tag_id = ID_STRING

    def __init__(StringTag self, value = ""):
        self.value_ = str(value)

{{include("AbstractBaseImmutableTag.pyx", cls_name="StringTag")}}


    @property
    def py_str(StringTag self) -> str:
        """
        A python string representation of the class.
        """
        return self.value_

    @property
    def py_data(self):
        return self.py_str

    def __repr__(StringTag self):
        return f"{self.__class__.__name__}(\"{self.py_str}\")"

    cdef str _to_snbt(StringTag self):
        return f"\"{escape(self.py_str)}\""

    cdef void write_payload(
        StringTag self,
        object buffer: BytesIO,
        bint little_endian,
        string_encoder: EncoderType,
    ) except *:
        write_string(self.value_, buffer, little_endian, string_encoder)

    def __str__(StringTag self):
        return self.py_str
