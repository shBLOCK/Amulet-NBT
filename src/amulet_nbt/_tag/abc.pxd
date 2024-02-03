from amulet_nbt._tag._cpp cimport TagNode


cdef class AbstractBase:
    pass


cdef class AbstractBaseTag(AbstractBase):
    cdef TagNode to_node(self)


cdef class AbstractBaseImmutableTag(AbstractBaseTag):
    pass


cdef class AbstractBaseMutableTag(AbstractBaseTag):
    pass
