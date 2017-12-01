include ActionView::Helpers::NumberHelper
module StripeTool

  # returns the quantity for a Stripe Product object
  def self.product_quantity(product)
    product.skus.data[0].inventory.quantity + 1
  end

  def self.product_plan_options(plans, prod_id)
    freq = {"Weekly" => 1, "Bimonthly" => 2, "Monthly" => 3}
    plan_opts = plans.data.select{|plan| plan.metadata.prod_id == prod_id }
    plan_opts.sort!{|a,b| freq[a.metadata.frequency] <=> freq[b.metadata.frequency] }
    plan_opts.map{|sub| "#{sub.metadata.frequency} / #{number_to_currency(sub.amount.to_f / 100)} per bag" }
  end

  def self.find_plan(plans, plan_id, prod_id)
    prod_plans = plans.select{|plan| (plan.metadata.prod_id == prod_id)}
    interval = /\w+/.match(plan_id)[0].downcase.insert(0, '-')
    plan = prod_plans.select{|plan| plan.id.include?(interval) }
  end

  def self.selected_plan(plans, plan_id)
    plans.select{|plan| plan.plan_id == plan_id}
  end

  def self.create_order(customer)
    valid_shipping_address = customer.valid_shipping_address?
    begin
      order = Stripe::Order.create(
        currency: 'usd',
        customer: customer.stripe_customer_id,
        items: customer.carted_items,
        shipping: {
          name: customer.full_name,
          address: valid_shipping_address ? customer.customer_address : customer.default_address
        }
      )
    rescue => error
      sku_id = error.message.split(': ')[1].split(' ')[0]
      sku_object = Stripe::SKU.retrieve(id: sku_id)
      product = Stripe::Product.retrieve(id: sku_object.product)
      new_error_message = error.message.gsub(sku_id, product.name)
      return { order: new_error_message, valid_shipping_address: valid_shipping_address, catch: 'It Broke' }
    end
    return { order: order, valid_shipping_address: valid_shipping_address, 'catch': 'All good in the hood'}
  end

  def self.customer_shipping_update(customer)
    stripe_customer = Stripe::Customer.retrieve(customer.stripe_customer_id)
    address = {
      name: customer.full_name,
      address: {
        line1: customer.address,
        line2: customer.Address2,
        city: customer.city,
        state: customer.state,
        postal_code: customer.zip_code
      }
    }
    stripe_customer.shipping = address
    stripe_customer.save
  end
end
