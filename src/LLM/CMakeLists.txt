qt_add_library(LLMModule STATIC)

qt_add_qml_module(LLMModule
    URI QGroundControl.LLM
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        ChatWidget.qml
    SOURCES
        LLMClient.cc
        LLMClient.h
    IMPORTS
        QGC
)

target_link_libraries(LLMModule
    PRIVATE
        Qt6::Core
        Qt6::Qml
        Qt6::Network
        QGroundControlModule
)

target_include_directories(LLMModule PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
