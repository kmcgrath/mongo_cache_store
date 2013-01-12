# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')


class MongoCacheStoreTestSaveClass

  attr_reader :set_me
  def initialize(set_me)
    @set_me = set_me
  end

end


module ActiveSupport 
  module Cache
    shared_examples "a cache store" do
      describe "Caching" do
    
        it "can write values" do
          @store.write('forever!', 'I live forever!')
          @store.fetch('forever!').should == "I live forever!"
        end

        it "can expire" do
          @store.fetch 'fnord', expires_in: 10.seconds do 
            "I am vaguely disturbed."
          end
          @store.exist?("fnord").should == true

          sleep 11 

          response = @store.fetch 'fnord'
          response.should == nil
        end

        it "can cache a hash" do
          @store.write('hashme',
            {"1"=>{:name=>"Uptime", :zenoss_instance=>"cust", :path=>"/zport/RenderServer/render?gopts=k4VJvRM2K1Dahl3RzJWcqoicTSIz0QJ1Ja10idqC412ptG5_lrmcroRy3BDIqioB561tB4UjtjSg1ib_YaGOXBWOEHBhPbEmA6ZXXjd8LiIOmItqTDZjuFkZvOV38_CF_YEi7t9xUtFKOIxibyVo67jzbyK6P-ORc7i07rK5GUYeA2CnJxm4UDCNKcKRpDCzmdzR-NwcOp0w55KH8YeU6NpgHyM_tpu8G42d7nBQebs1DKvn20sktezqy_LiIizKk3eMzDW-c8w1EZTESWa4rIihXfHrrv9PNxvCw41wU9f3dxQt2c3OFfhSx6riSUbeVsUNEo6s_35KdKJkbr6rEZaaxL2RGR47eLBzifIcZAg="}, "2"=>{:name=>"CPU Utilization", :zenoss_instance=>"cust", :path=>"/zport/RenderServer/render?gopts=WN-Oc9wB_CFbVKzzN75ij-qQcZ6lSOC3jj_ALTzkdMEZ_EzgcvfWOdU7vmlrm9MFY6zrOUeW2Z_uzyJkhRrl_81bVs96xoa7y2S29NVU_oSIIxQj1rUElV04u3wGRXnEbfyYPjLp0m6QEDOthqCs3SLcc7jKkCI15V0Js1b6FpFleWdmO9dCMLvKqdBiE-yhSjfwPS7Rh0wPLAoxXTyIkFFHHBXIu_g69_xnESZhYz0rAWn0W0Ag5N46LuNqwbzW1PwIfczY1Hqw2iKQAq1C4fMry3DNiQvnRmUZdF_w11quhIo-XccH1em3iopVdyy6ik83vMvJN3DfhLUbXcZjnA=="}, "3"=>{:name=>"Memory Utilization", :instance=>"cust", :path=>"/zport/RenderServer/render?gopts=_E6b8KAZjy9xzEYtckX_RDQOsGfIRZnG5WRu7ekbUIlsgWmNZNJ8AgEfr7AM0rV6lZMC4PzCPacRN1zeVQ-nHgTBBDbq4sIQuUMl3ETW9DRM2wgjrmnCRwcl7Dz_qGL6PWkhsJzhQ231SuNi7pM6mDw8dbE_pmZ3F6xKa7_8frJLWoMGLji8sIklFf45YckRkIohkMsffZKMsIspx8JEOvR9mP24vGs0Wv4gRXxqFoE1FlgchuKf2KDvWbwp92RrdOmhOAqMxHWmNA2faAC75072ao9bf6UnxZUu5WFUcNsvJJFcEl2U30TEX5vyjf_9C-1Rvnyf8Q6ajvRKA1VNIl6fpItv8dsKTNViX27RWsI="}, "4"=>{:name=>"Swap", :instance=>"cust", :path=>"/zport/RenderServer/render?gopts=nBpbINZ6hhzV8IUJq49zWOTsQ4hX5F5ZGPyoHZ6KWPUx_4Xk0_URWbZPQO4yicu14u81lDFqfRCoFTwofkA0NJIqoOQfAx2gWrwbE7RtulqYeMol47KWQpSITLSV4Mkh1Sbp9VZqpc4YVjiu1EvWSOIHCeUPXZPSBWFh0R2VoPB_VutBricdimwkvRsHbU9-BlKyJcT-_vEnTMi2MHlB3iKWY329OkN-J2chI3MtoLvSw9sN2LJbrO4ynFQPX4WFY9D18Zhv1bzOapn0XcCsxj88XHZ2eZeEZ0uv33_9EKSVxKtOOYo3Y08mjEKduOme"}, "5"=>{:name=>"Load Average", :instance=>"cust", :path=>"/zport/RenderServer/render?gopts=0y-dExjiyMFT0yWeOf-FR3hBIgIVZZortlKSFUETQYjwMuSDfhB-JhsEYI-feAC0Bmh5T8fZQRuYi5MkD3C2S6Qwd_kzvPrjwxCfxjTaQzidN-DxlWjqTkTfZ-AiPQ3F8JVXr-8kP8ZA10XDcV2VpIHJwZatzxDBVk7isEdKAXEJm-1X_TY7BCdU9uFlcBT1XGEYESM5anyR3282Z77yiYX6PsUcoPwFtLzg1l6Ql8cda8n4d2zLK4ZBX5G25ZQoC0MAmHZPyXRIsI-GGZjKcvXHjZ350tEpyvPiSX8a7PG-dRtWIGEEecM9czU3MF5Xzl-qOVfoRWc8pmlc-5E37Z5TcAoZpUHSlssJdjwoLfOlhFkLGyAVZpVXRCVRWdXNxilLS9N4GbuIEqhsEILyM0MzPvEHwPO3rcPSlzcS4s_SXnjp6XLg2bB6NZjAvbz5Vyb6OPg-8b9C-MmzcpWzVHzP5nYo9RVPR_lpFcmOBUSO_cJO22pIqqMyn1vXbtVz"}, "6"=>{:name=>"Paging", :instance=>"cust", :path=>"/zport/RenderServer/render?gopts=N7sjMwpMD3JE0ZNya07IgWj6t7yn7uX4GJ1XHlmyhRcqcea0HpfXTen6ptASVAZIvWT7fW4kufkvtNBsxKfDMX9JMzqoR-kpfWqoRRfI3eGmqYecg6gcQgXSEnu5Mzf4r-lbo1_Cqp8dYuSmC37uWrKi0gTWVr54ZmQ6w4dSymQ4xSkCH2-MO1X8wxZdtm804NJy6yQ4l7JZYBkWD9rABoPhVfZq4mZpHmZN27UlbK14Z9R3EEF6MG0jKCbJ7gJVEjpOoX_y5ka4S3aRULFSByrZIA290_ZMO21DAnsJbJyMXAEP9r8UanaotdVrPLSOXJkYD4WvdcdDeZ3wMtvdL42oHdhwLDyG9J8i9GkcvwsU04MlTTl270LkX31HJjxjB8IChpDke-9LEmxG_1icmGcAcWr26gTk9HOULwTyso4sX_ZqqCnrrnRRQLCpCZtlqxIB9iAMUtSdkEUdZlsAuw=="}},
            expires_in: 1.hour
          )

          hash = @store.read('hashme')
          hash["1"].should be_a_kind_of(Hash)

        end

        it "can cache class instances" do
          @store.fetch 'my_class', expires_in: 30.seconds do
            MongoCacheStoreTestSaveClass.new('what did i say?')
          end

          my_class = @store.fetch 'my_class'
          my_class.set_me.should == 'what did i say?'
        end

        it "can use a hash as a key" do
          hash_key = {
            :class_name => 'my_class',
            :option2 => 2
          }

          miss_key = {
            :class_name => 'my_class',
            :option2 => 1
          }

          hit_key = {
            :class_name => 'my_class',
            :option2 => 2
          }


          @store.fetch(hash_key, expires_in: 30.seconds) do
            MongoCacheStoreTestSaveClass.new('what did i say?')
          end

          my_class = @store.fetch(hash_key)
          my_class.set_me.should == 'what did i say?'

          my_class = @store.fetch(hit_key)
          my_class.set_me.should == 'what did i say?'

          my_class = @store.fetch(miss_key)
          my_class.should == nil
         
        end

        after(:all) do
          @store.clear
        end 
      end
    end


    describe MongoCacheStore do
      describe "initializing" do
        it "can take a Mongo::DB object" do
          db = Mongo::DB.new('mongo_store_test', Mongo::Connection.new)
          store = ActiveSupport::Cache::MongoCacheStore.new(:TTL, db: db)
        end
      end

      describe "TTL Caching" do
        it_behaves_like "a cache store" 
        before(:all) do
          db = Mongo::DB.new('mongo_cache_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:TTL, db: db)
        end
      end

      describe "TTL Caching Force Serialization" do
        it_behaves_like "a cache store" 
        before(:all) do
          db = Mongo::DB.new('mongo_cache_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:TTL, db: db, serialize: :always)
        end
      end

      describe "OneTTL Caching" do
        it_behaves_like "a cache store" 
        before(:all) do
          db = Mongo::DB.new('mongo_cache_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:OneTTL, db: db)
        end
      end

      describe "OneTTL Caching Force Serialization" do
        it_behaves_like "a cache store" 
        before(:all) do
          db = Mongo::DB.new('mongo_cache_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:OneTTL, db: db, serialize: :always)
        end
      end

      describe "Standard Caching" do
        it_behaves_like "a cache store"
        before(:all) do
          db = Mongo::DB.new('mongo_cache_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:Standard, db: db)
        end
      end

      describe "Standard Caching Force Serialization" do
        it_behaves_like "a cache store"
        before(:all) do
          db = Mongo::DB.new('mongo_cache_store_test', Mongo::Connection.new)
          @store = ActiveSupport::Cache::MongoCacheStore.new(:Standard, db: db, serialize: :always)
        end
      end


    end
  end
end
