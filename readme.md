# ![fireworks_logo](.github/images/fireworks_logo.png)

**Fireworks** is a software development kit developed for the creation 
of 3d graphic programs such as games and simulations.

It is inspired by Flutter and focuses to provide a pleasant developer experience just as good.
With Fireworks, you can create games and other 3d real-time applications for mobile, desktop and the web.
The sdk is available for Windows, Linux and macOS.

Just like other engines, Fireworks is free of charge as long you are non-commercial. 
If you revenue exceeds 5000$ you have to get a commercial license that forces 
you to pay 5% of you further revenue.
# Fireworks source structure

**Quick overview**
````
fireworks/
  | - build/    # CI, build tools and build scripts.
  | - editor/   # Implementation of the user interface and integration for several IDEs.
  | - engine/   # Engine API & runtime implementation.
  | - runner/   # CLI-tool of the SDK, providing hot reload mechanism and other devtools.
````