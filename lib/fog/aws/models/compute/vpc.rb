module Fog
  module Compute
    class AWS
      class VPC < Fog::Model
        identity :id,                :aliases => 'vpcId'

        attribute :state
        attribute :cidr_block,       :aliases => 'cidrBlock'
        attribute :dhcp_options_id,  :aliases => 'dhcpOptionsId'
        attribute :tags,             :aliases => 'tagSet'
        attribute :tenancy,          :aliases => 'instanceTenancy'
        attribute :is_default,       :aliases => 'isDefault'

        def subnets
          service.subnets(:filters => {'vpcId' => self.identity}).all
        end

        def initialize(attributes={})
          self.dhcp_options_id ||= "default"
          self.tenancy ||= "default"
          super
        end

        def ready?
          requires :state
          state == 'available'
        end

        def is_default?
          require :is_default
          is_default
        end

        # Removes an existing vpc
        #
        # vpc.destroy
        #
        # ==== Returns
        #
        # True or false depending on the result
        #

        def destroy
          requires :id

          service.delete_vpc(id)
          true
        end

        # Create a vpc
        #
        # >> g = AWS.vpcs.new(:cidr_block => "10.1.2.0/24")
        # >> g.save
        #
        # == Returns:
        #
        # True or an exception depending on the result. Keep in mind that this *creates* a new vpc.
        # As such, it yields an InvalidGroup.Duplicate exception if you attempt to save an existing vpc.
        #

        def save
          requires :cidr_block

          data = service.create_vpc(cidr_block).body['vpcSet'].first
          new_attributes = data.reject {|key,value| key == 'requestId'}
          new_attributes = data.reject {|key,value| key == 'requestId' || key == 'tagSet' }
          merge_attributes(new_attributes)

          if tags = self.tags
            # expect eventual consistency
            Fog.wait_for { self.reload rescue nil }
            service.create_tags(
              self.identity,
              tags
            )
          end

          true
        end
      end
    end
  end
end
