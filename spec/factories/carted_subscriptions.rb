FactoryGirl.define do
  factory :carted_subscription do
    quantity 1
    plan_id 'Weekly / $42.00 per bag'
    status 'carted'
    customer_id 1
    grind 'Ground'
    interval 'week'
    interval_count 1
    plan_name 'bob-weekly'
    amount 4200
  end

  factory :subscribed_subscription, class: CartedSubscription do
    quantity 1
    plan_id 'Weekly / $42.00 per bag'
    status 'subscribed'
    customer_id 1
    grind 'Ground'
    interval 'week'
    interval_count 1
    plan_name 'bob-weekly'
    amount 4200
  end
end
