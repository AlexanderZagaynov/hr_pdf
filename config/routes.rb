# frozen_string_literal: true

Rails.application.routes.draw do
  controller :conversion do
    get  '', action: :new, as: :conversion
    post '', action: :create
  end
end
