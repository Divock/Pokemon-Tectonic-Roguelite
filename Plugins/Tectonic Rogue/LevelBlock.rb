##############################################################
# A class that defines the data about a level generation block.
##############################################################
class LevelBlock
    attr_reader :map_id
    attr_reader :map_name
    attr_reader :block_type
    attr_reader :connectable_dirs
    
    def initialize(map_id, map_name, block_type, metadataString)
        @map_id = map_id
        @map_name = map_name
        @block_type = block_type

        metadataString = metadataString.downcase

        @connectable_dirs = []
        @connectable_dirs.push(:north) if metadataString.include?("n")
        @connectable_dirs.push(:south) if metadataString.include?("s")
        @connectable_dirs.push(:east) if metadataString.include?("e")
        @connectable_dirs.push(:west) if metadataString.include?("w")

        raise _INTL("Block {1} has no valid directions!", designation) if @connectable_dirs.empty?

        if @connectable_dirs.length > 1 && %i[start exit].include?(block_type)
            raise _INTL("Start or Exit block {1} has more than one valid direction.", designation)
        end

        echoln("Loaded block #{designation}")
    end

    def designation
        return "#{@map_name} (#{@map_id})"
    end

    def hasAnyDir?(qualified_dirs = [])
        qualified_dirs.each do |qualified_dir|
            return true if @connectable_dirs.include?(qualified_dir)
        end
        return false
    end

    def getRandomAllowedDirection(qualified_dirs = [])
        dirs = []
        @connectable_dirs.each do |dir|
            next unless qualified_dirs.include?(dir)
            dirs.push(dir)
        end
        return dirs.sample
    end

    def getRandomOtherDirection(disqualified_dirs = [])
        dirs = []
        @connectable_dirs.each do |dir|
            next if disqualified_dirs.include?(dir)
            dirs.push(dir)
        end
        return dirs.sample
    end
end