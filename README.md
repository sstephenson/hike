Hike
====

Hike is a Ruby library for finding files in a set of paths.

    trail = Hike::Trail.new "/Users/sam/Projects/hike"
    trail.extensions.push ".rb"
    trail.paths.push "lib", "test"

    trail.find "hike/trail"
    # => "/Users/sam/Projects/hike/lib/hike/trail.rb"

    trail.find "test_trail"
    # => "/Users/sam/Projects/hike/test/test_trail.rb"

# Installation

    $ gem install hike

# License

Copyright (c) 2010 Sam Stephenson.

Released under the MIT license. See `LICENSE` for details.
