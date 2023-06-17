## This file is generated by tempita. Do not modify this file directly or your changes will get overwritten.
## To edit this file edit the template in template/src

from io import BytesIO
from copy import deepcopy
import warnings
from math import trunc, floor, ceil

from ._numeric cimport AbstractBaseNumericTag
from ._const cimport ID_FLOAT, ID_DOUBLE
from ._util cimport write_float, write_double, BufferContext, read_data, to_little_endian
from ._dtype import EncoderType
{{py:from template import include}}


cdef class AbstractBaseFloatTag(AbstractBaseNumericTag):
    """Abstract Base Class for all float Tag classes"""

    @property
    def py_float(AbstractBaseNumericTag self) -> float:
        """
        A python float representation of the class.
        The returned data is immutable so changes will not mirror the instance.
        """
        raise NotImplementedError

    @property
    def py_data(self):
        """
        A python representation of the class. Note that the return type is undefined and may change in the future.
        You would be better off using the py_{type} or np_array properties if you require a fixed type.
        This is here for convenience to get a python representation under the same property name.
        """
        return self.py_float



cdef inline FloatTag read_float_tag(BufferContext buffer, bint little_endian):
    cdef FloatTag tag = FloatTag.__new__(FloatTag)
    cdef float*pointer = <float*> read_data(buffer, 4)
    tag.value_ = pointer[0]
    to_little_endian(&tag.value_, 4, little_endian)
    return tag


cdef class FloatTag(AbstractBaseFloatTag):
    """A single precision float class."""
    tag_id = ID_FLOAT

    def __init__(FloatTag self, value = 0):
        self.value_ = float(value)

{{include("AbstractBaseFloatTag.pyx", cls_name="FloatTag")}}

    cdef str _to_snbt(FloatTag self):
        return f"{self.value_}f"

    cdef void write_payload(
        FloatTag self,
        object buffer: BytesIO,
        bint little_endian,
        string_encoder: EncoderType,
    ) except *:
        write_float(self.value_, buffer, little_endian)


cdef inline DoubleTag read_double_tag(BufferContext buffer, bint little_endian):
    cdef DoubleTag tag = DoubleTag.__new__(DoubleTag)
    cdef double *pointer = <double *> read_data(buffer, 8)
    tag.value_ = pointer[0]
    to_little_endian(&tag.value_, 8, little_endian)
    return tag


cdef class DoubleTag(AbstractBaseFloatTag):
    """A double precision float class."""
    tag_id = ID_DOUBLE

    def __init__(DoubleTag self, value = 0):
        self.value_ = float(value)

{{include("AbstractBaseFloatTag.pyx", cls_name="DoubleTag")}}

    cdef str _to_snbt(DoubleTag self):
        return f"{self.value_}d"

    cdef void write_payload(
        DoubleTag self,
        object buffer: BytesIO,
        bint little_endian,
        string_encoder: EncoderType,
    ) except *:
        write_double(self.value_, buffer, little_endian)
