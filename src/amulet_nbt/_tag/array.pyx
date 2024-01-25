## This file is generated from a template.
## Do not modify this file directly or your changes will get overwritten.
## Edit the accompanying .pyx.tp file instead.

## This file is generated by tempita. Do not modify this file directly or your changes will get overwritten.
## To edit this file edit the template in template/src

import numpy
cimport numpy
numpy.import_array()
from io import BytesIO
from copy import deepcopy
import warnings

from cython.operator cimport dereference
from libc.stdint cimport (
    int8_t,
    int16_t,
    int32_t,
    int64_t,
    uint32_t
)
from libcpp.memory cimport make_shared
from amulet_nbt._nbt.array cimport Array
from amulet_nbt._nbt cimport TagNode, CByteTag, CIntTag, CLongTag, CByteArrayTag, CIntArrayTag, CLongArrayTag
from amulet_nbt._tag.abc cimport AbstractBaseMutableTag
# from amulet_nbt._const cimport CommaSpace, ID_BYTE_ARRAY, ID_INT_ARRAY, ID_LONG_ARRAY
# from amulet_nbt._dtype import EncoderType


cdef class AbstractBaseArrayTag(AbstractBaseMutableTag):
    def __getitem__(AbstractBaseArrayTag self, item):
        raise NotImplementedError

    def __setitem__(AbstractBaseArrayTag self, key, value):
        raise NotImplementedError

    def __array__(AbstractBaseArrayTag self, dtype=None):
        raise NotImplementedError

    def __len__(AbstractBaseArrayTag self):
        raise NotImplementedError

    @property
    def np_array(AbstractBaseArrayTag self):
        """
        A numpy array holding the same internal data.
        Changes to the array will also modify the internal state.
        """
        raise NotImplementedError

    @property
    def py_data(self):
        """
        A python representation of the class. Note that the return type is undefined and may change in the future.
        You would be better off using the py_{type} or np_array properties if you require a fixed type.
        This is here for convenience to get a python representation under the same property name.
        """
        return self.np_array


cdef class ByteArrayTag(AbstractBaseArrayTag):
    """This class behaves like an 1D Numpy signed integer array with each value stored in a byte."""
    # tag_id = ID_BYTE_ARRAY

    def __init__(ByteArrayTag self, object value = ()):
        cdef numpy.ndarray arr = numpy.asarray(value, numpy.dtype("int8")).ravel()
        self.cpp = make_shared[CByteArrayTag](arr.size)
        cdef size_t i
        for i in range(arr.size):
            dereference(self.cpp)[i] = arr[i]

    @staticmethod
    cdef ByteArrayTag wrap(CByteArrayTagPtr cpp):
        cdef ByteArrayTag tag = ByteArrayTag.__new__(ByteArrayTag)
        tag.cpp = cpp
        return tag

    cdef TagNode to_node(self):
        cdef TagNode node
        node.emplace[CByteArrayTagPtr](self.cpp)
        return node

    def __eq__(ByteArrayTag self, object other):
        if not isinstance(other, ByteArrayTag):
            return False
        cdef ByteArrayTag tag = other
        return dereference(self.cpp) == dereference(tag.cpp)

#
#     # cdef str _to_snbt(ByteArrayTag self):
#     #     cdef long long elem
#     #     cdef list tags = []
#     #     for elem in self.cpp:
#     #         tags.append(f"{elem}B")
#     #     return f"[B;{CommaSpace.join(tags)}]"
#
#
#     # @property
#     # def np_array(ByteArrayTag self):
#     #     """
#     #     A numpy array holding the same internal data.
#     #     Changes to the array will also modify the internal state.
#     #     """
#     #     return self.cpp
#
#     # def __repr__(ByteArrayTag self):
#     #     return f"{self.__class__.__name__}({list(self.cpp)})"
#
#     def __eq__(ByteArrayTag self, other):
#         cdef ByteArrayTag other_
#         if isinstance(other, ByteArrayTag):
#             other_ = other
#             return dereference(self.cpp) == dereference(other_.cpp)
#         return NotImplemented
#
#     def __getitem__(ByteArrayTag self, uint32_t item):
#         return dereference(self.cpp)[item]
#
#     def __setitem__(ByteArrayTag self, uint32_t key, CByteTag value):
#         dereference(self.cpp)[key] = value
#
#     # def __array__(ByteArrayTag self, dtype=None):
#     #     return numpy.asarray(self.cpp, dtype=dtype)
#
#     def __len__(ByteArrayTag self):
#         return dereference(self.cpp).size()


cdef class IntArrayTag(AbstractBaseArrayTag):
    """This class behaves like an 1D Numpy signed integer array with each value stored in a int."""
    # tag_id = ID_INT_ARRAY

    def __init__(IntArrayTag self, object value = ()):
        cdef numpy.ndarray arr = numpy.asarray(value, numpy.int32).ravel()
        self.cpp = make_shared[CIntArrayTag](arr.size)
        cdef size_t i
        for i in range(arr.size):
            dereference(self.cpp)[i] = arr[i]

    @staticmethod
    cdef IntArrayTag wrap(CIntArrayTagPtr cpp):
        cdef IntArrayTag tag = IntArrayTag.__new__(IntArrayTag)
        tag.cpp = cpp
        return tag

    cdef TagNode to_node(self):
        cdef TagNode node
        node.emplace[CIntArrayTagPtr](self.cpp)
        return node

    def __eq__(IntArrayTag self, object other):
        if not isinstance(other, IntArrayTag):
            return False
        cdef IntArrayTag tag = other
        return dereference(self.cpp) == dereference(tag.cpp)

#
#     # cdef str _to_snbt(IntArrayTag self):
#     #     cdef long long elem
#     #     cdef list tags = []
#     #     for elem in self.cpp:
#     #         tags.append(f"{elem}")
#     #     return f"[I;{CommaSpace.join(tags)}]"
#
#
#     # @property
#     # def np_array(IntArrayTag self):
#     #     """
#     #     A numpy array holding the same internal data.
#     #     Changes to the array will also modify the internal state.
#     #     """
#     #     return self.cpp
#
#     # def __repr__(IntArrayTag self):
#     #     return f"{self.__class__.__name__}({list(self.cpp)})"
#
#     def __eq__(IntArrayTag self, other):
#         cdef IntArrayTag other_
#         if isinstance(other, IntArrayTag):
#             other_ = other
#             return dereference(self.cpp) == dereference(other_.cpp)
#         return NotImplemented
#
#     def __getitem__(IntArrayTag self, uint32_t item):
#         return dereference(self.cpp)[item]
#
#     def __setitem__(IntArrayTag self, uint32_t key, CIntTag value):
#         dereference(self.cpp)[key] = value
#
#     # def __array__(IntArrayTag self, dtype=None):
#     #     return numpy.asarray(self.cpp, dtype=dtype)
#
#     def __len__(IntArrayTag self):
#         return dereference(self.cpp).size()


cdef class LongArrayTag(AbstractBaseArrayTag):
    """This class behaves like an 1D Numpy signed integer array with each value stored in a long."""
    # tag_id = ID_LONG_ARRAY

    def __init__(LongArrayTag self, object value = ()):
        cdef numpy.ndarray arr = numpy.asarray(value, numpy.int64).ravel()
        self.cpp = make_shared[CLongArrayTag](arr.size)
        cdef size_t i
        for i in range(arr.size):
            dereference(self.cpp)[i] = arr[i]

    @staticmethod
    cdef LongArrayTag wrap(CLongArrayTagPtr cpp):
        cdef LongArrayTag tag = LongArrayTag.__new__(LongArrayTag)
        tag.cpp = cpp
        return tag

    cdef TagNode to_node(self):
        cdef TagNode node
        node.emplace[CLongArrayTagPtr](self.cpp)
        return node

    def __eq__(LongArrayTag self, object other):
        if not isinstance(other, LongArrayTag):
            return False
        cdef LongArrayTag tag = other
        return dereference(self.cpp) == dereference(tag.cpp)

#
#     # cdef str _to_snbt(LongArrayTag self):
#     #     cdef long long elem
#     #     cdef list tags = []
#     #     for elem in self.cpp:
#     #         tags.append(f"{elem}L")
#     #     return f"[L;{CommaSpace.join(tags)}]"
#
#
#     # @property
#     # def np_array(LongArrayTag self):
#     #     """
#     #     A numpy array holding the same internal data.
#     #     Changes to the array will also modify the internal state.
#     #     """
#     #     return self.cpp
#
#     # def __repr__(LongArrayTag self):
#     #     return f"{self.__class__.__name__}({list(self.cpp)})"
#
#     def __eq__(LongArrayTag self, other):
#         cdef LongArrayTag other_
#         if isinstance(other, LongArrayTag):
#             other_ = other
#             return dereference(self.cpp) == dereference(other_.cpp)
#         return NotImplemented
#
#     def __getitem__(LongArrayTag self, uint32_t item):
#         return dereference(self.cpp)[item]
#
#     def __setitem__(LongArrayTag self, uint32_t key, CLongTag value):
#         dereference(self.cpp)[key] = value
#
#     # def __array__(LongArrayTag self, dtype=None):
#     #     return numpy.asarray(self.cpp, dtype=dtype)
#
#     def __len__(LongArrayTag self):
#         return dereference(self.cpp).size()
