module Puppet::Parser::Functions
    newfunction(:hadoop_storages, :type => :rvalue, :doc => "Parse Hadoop storage array.") do |arguments|
        raise(Puppet::ParseError, "hadoop_storages(): Wrong number of arguments") if arguments.size != 1
        raise(Puppet::ParseError, "hadoop_storages(): Not an array") if !arguments[0].is_a?(Array)

        storages = arguments[0]
        ah=[]
        as=[]
        storages.each do |s|
            if !s then
                raise(Puppet::ParseError, 'hadoop_storages(): Undefined value of the storage path')
            end

            #[DISK]file:///data/1
            r = s.scan(/(\[[^\]]*\])?(([A-Za-z0-9]*):\/\/)?(.*)/)[0]

            h = Hash.new()
            h['type'] = r[0] ? r[0].upcase() : ''
            h['schema'] = r[2] ? r[2] : 'file'
            h['path'] = r[3]
            ah.push(h)
            as.push(r[3])
        end

        {
            'paths' => as,
            'storages' => ah,
        }
    end
end
