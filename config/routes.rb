Rails.application.routes.draw do
  resources :photos do
		member do
			get 'approve'
			get 'deny'
			get 'favorite'
			get 'reject'
			get 'rotate'
			get 'queue'
		end

		collection do
			get 'next'
			get 'controls'
			get 'pending'
			get 'approved'
			get 'denied'
			get 'recent'
			get 'scan'
			get 'reset_and_rescan'
			get 'auto_approve'
			get 'collect_all'
			post 'collect_all'
			get 'collect_all_and_copy_all_to_usb'
			post 'collect_all_and_copy_all_to_usb'
			get 'rename_usb'
			post 'rename_usb'
		end
	end

	resources :controls do
		collection do	
			get 'state'
		end
	end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
	get '/', :to => redirect('/slideshow')

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
