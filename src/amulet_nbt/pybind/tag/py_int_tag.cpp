#include <string>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/operators.h>

#include <amulet_nbt/tag/wrapper.hpp>

namespace py = pybind11;


#define PyInt(CLSNAME, BYTEWIDTH, BITPOW, SIGNBIT, MAGBITS, TAGID)\
    py::class_<AmuletNBT::CLSNAME##Wrapper, AmuletNBT::AbstractBaseIntTag> CLSNAME(m, #CLSNAME,\
        "A "#BYTEWIDTH" byte integer class.\n"\
        "\n"\
        "Can Store numbers between -(2^"#BITPOW") and (2^"#BITPOW" - 1)"\
    );\
    CLSNAME.def_property_readonly_static("tag_id", [](py::object) {return TAGID;});\
    CLSNAME.def(\
        py::init([PyIntCls](py::object py_value) {\
            /* cast to a python int */\
            py::object py_int = PyIntCls(py_value);\
            /* get the magnitude bits */\
            AmuletNBT::CLSNAME value = py_int.attr("__and__")(py::cast(MAGBITS)).cast<AmuletNBT::CLSNAME>();\
            /* get the sign bits */\
            if (py_int.attr("__and__")(py::cast(SIGNBIT)).cast<bool>()){value -= SIGNBIT;}\
            return AmuletNBT::CLSNAME##Wrapper(value);\
        }),\
        py::arg("value") = 0,\
        py::doc("__init__(self: amulet_nbt."#CLSNAME", value: typing.SupportsInt) -> None")\
    );\
    CLSNAME.def_readonly(\
        "py_int",\
        &AmuletNBT::CLSNAME##Wrapper::tag,\
        py::doc(\
            "A python int representation of the class.\n"\
            "\n"\
            "The returned data is immutable so changes will not mirror the instance."\
        )\
    );\
    CLSNAME.def_readonly(\
        "py_data",\
        &AmuletNBT::CLSNAME##Wrapper::tag,\
        py::doc(\
            "A python representation of the class. Note that the return type is undefined and may change in the future.\n"\
            "\n"\
            "You would be better off using the py_{type} or np_array properties if you require a fixed type.\n"\
            "This is here for convenience to get a python representation under the same property name.\n"\
        )\
    );\
    CLSNAME.def(\
        "__repr__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self){\
            return #CLSNAME "(" + std::to_string(self.tag) + ")";\
        }\
    );\
    CLSNAME.def(\
        "__str__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self){\
            return std::to_string(self.tag);\
        }\
    );\
    CLSNAME.def(\
        py::pickle(\
            [](const AmuletNBT::CLSNAME##Wrapper& self){\
                return self.tag;\
            },\
            [](AmuletNBT::CLSNAME state){\
                return AmuletNBT::CLSNAME##Wrapper(state);\
            }\
        )\
    );\
    CLSNAME.def(\
        "__copy__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self){\
            return self;\
        }\
    );\
    CLSNAME.def(\
        "__deepcopy__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self, py::dict){\
            return self;\
        },\
        py::arg("memo")\
    );\
    CLSNAME.def(\
        "__hash__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self){\
            return py::hash(py::make_tuple(TAGID, self.tag));\
        }\
    );\
    CLSNAME.def(\
        "__int__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self){\
            return self.tag;\
        }\
    );\
    CLSNAME.def(\
        "__float__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self) -> py::float_ {\
            return py::cast(self.tag);\
        }\
    );\
    CLSNAME.def(\
        "__bool__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self){\
            return self.tag != 0;\
        }\
    );\
    CLSNAME.def(\
        "__eq__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self, const AmuletNBT::CLSNAME##Wrapper& other){\
            return self.tag == other.tag;\
        },\
        py::is_operator()\
    );\
    CLSNAME.def(\
        "__ge__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self, const AmuletNBT::CLSNAME##Wrapper& other){\
            return self.tag >= other.tag;\
        },\
        py::is_operator()\
    );\
    CLSNAME.def(\
        "__gt__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self, const AmuletNBT::CLSNAME##Wrapper& other){\
            return self.tag > other.tag;\
        },\
        py::is_operator()\
    );\
    CLSNAME.def(\
        "__le__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self, const AmuletNBT::CLSNAME##Wrapper& other){\
            return self.tag <= other.tag;\
        },\
        py::is_operator()\
    );\
    CLSNAME.def(\
        "__lt__",\
        [](const AmuletNBT::CLSNAME##Wrapper& self, const AmuletNBT::CLSNAME##Wrapper& other){\
            return self.tag < other.tag;\
        },\
        py::is_operator()\
    );


void init_int(py::module& m) {
    py::object PyIntCls = py::module::import("builtins").attr("int");
    PyInt(ByteTag, 1, 7, 0x80, 0x7F, 1)
    PyInt(ShortTag, 2, 15, 0x8000, 0x7FFF, 2)
    PyInt(IntTag, 4, 31, 0x80000000, 0x7FFFFFFF, 3)
    PyInt(LongTag, 8, 63, 0x8000000000000000, 0x7FFFFFFFFFFFFFFF, 4)
};
