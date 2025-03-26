add_custom_target(interface
        DEPENDS interface_web_host interface_web_ui
)
add_custom_target(interface_web_ui
        DEPENDS interface_web_ui_surfaces interface_web_ui_view_port
)
add_subdirectory(web_host)
add_subdirectory(web_ui/surfaces)
add_subdirectory(web_ui/view_port)