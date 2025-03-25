add_custom_target(interface
        DEPENDS interface_web interface_editor
)
add_subdirectory(web_app)
add_subdirectory(editor)