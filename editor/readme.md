## Web interface parts architecture

````
| - interface/
    | - ide_plugins/        
        # IDE plugins which implements web views and superficial buttons, structure and controls.
        
    | - web_host/           
        # Web app hoster and the communication between the surfaces and view port.
        
    | - web_ui/
        | - surfaces/       
            # Flutter based ui of development tools and view port communication.
        
        | - view_port/      
            # Engine RT based view port for viewing the project in debug cycle.
````