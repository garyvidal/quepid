# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    module Import
      class RatingsControllerTest < ActionController::TestCase
        let(:user)  { users(:random) }
        let(:acase) { cases(:import_ratings_case) }
        let(:query) { queries(:import_ratings_query) }

        before do
          @controller = Api::V1::Import::RatingsController.new

          login_user user
        end

        describe '#create' do
          test 'creates new queries when needed' do
            data = {
              case_id: acase.id,
              ratings: [
                { query_text: 'dog', doc_id: '123', rating: 1 },
                { query_text: 'dog', doc_id: '234', rating: 2 },
                { query_text: 'dog', doc_id: '456', rating: 3 }
              ],
            }
            assert_difference 'acase.queries.count' do
              post :create, data

              assert_response :ok
            end
          end

          test 'does not create new queries when already present' do
            data = {
              case_id: acase.id,
              ratings: [
                { query_text: query.query_text, doc_id: '123', rating: 1 },
                { query_text: query.query_text, doc_id: '234', rating: 2 },
                { query_text: query.query_text, doc_id: '456', rating: 3 }
              ],
            }
            assert_no_difference 'acase.queries.count' do
              post :create, data

              assert_response :ok
            end
          end

          test 'creates new ratings when needed' do
            data = {
              case_id: acase.id,
              ratings: [
                { query_text: 'dog', doc_id: '123', rating: 1 },
                { query_text: 'dog', doc_id: '234', rating: 2 },
                { query_text: 'dog', doc_id: '456', rating: 3 }
              ],
            }
            assert_difference 'Rating.count', 3 do
              post :create, data

              assert_response :ok
            end
          end

          test 'updates existing ratings' do
            data = {
              case_id: acase.id,
              ratings: [
                { query_text: query.query_text, doc_id: '123', rating: 1 },
                { query_text: query.query_text, doc_id: '234', rating: 2 },
                { query_text: query.query_text, doc_id: '456', rating: 3 }
              ],
            }

            rating = Rating.where(query_id: query.id, doc_id: '123').first

            assert_not_equal rating.rating, 1

            assert_no_difference 'Rating.count' do
              post :create, data

              assert_response :ok

              rating.reload

              assert_equal 1, rating.rating
            end
          end

          test 'clears existing ratings if flag is set to true' do
            data = {
              case_id:       acase.id,
              clear_queries: true,
              ratings:       [
                { query_text: query.query_text, doc_id: '123', rating: 1 },
                { query_text: query.query_text, doc_id: '234', rating: 2 }
              ],
            }

            assert_difference 'Rating.count', -1 do
              post :create, data

              assert_response :ok
            end
          end

          test 'deletes unused queries if flag is set to true' do
            data = {
              case_id:       acase.id,
              clear_queries: true,
              ratings:       [
                { query_text: 'dog', doc_id: '123', rating: 1 },
                { query_text: 'dog', doc_id: '234', rating: 2 },
                { query_text: 'dog', doc_id: '456', rating: 3 }
              ],
            }
            assert_no_difference 'acase.queries.count' do
              post :create, data

              assert_response :ok
            end

            query.reload

            assert query.deleted
          end
        end
      end
    end
  end
end
