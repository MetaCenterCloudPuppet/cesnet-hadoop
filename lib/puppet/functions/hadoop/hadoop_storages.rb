# This is an autogenerated function, ported from the original legacy version.
# It /should work/ as is, but will not have all the benefits of the modern
# function API. You should see the function docs to learn how to add function
# signatures for type safety and to document this function using puppet-strings.
#
# https://puppet.com/docs/puppet/latest/custom_functions_ruby.html
#
# ---- original file header ----

# ---- original file header ----
#
# @summary
#   Parse Hadoop storage array.
#
Puppet::Functions.create_function(:'hadoop::hadoop_storages') do
  # @param arguments
  #   The original array of arguments. Port this to individually managed params
  #   to get the full benefit of the modern function API.
  #
  # @return [Data type]
  #   Describe what the function returns here
  #
  dispatch :default_impl do
    # Call the method named 'default_impl' when this is matched
    # Port this to match individual params for better type safety
    repeated_param 'Any', :arguments
  end


  def default_impl(*arguments)
    
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