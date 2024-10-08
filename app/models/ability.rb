class Ability
  include CanCan::Ability

  def initialize(user)
    if user.superadmin?
      can :manage, User
      can :manage, Unit
      can :manage, UserLog
      can :manage, Role
      can :role, :unitadmin
      can :role, :user
      cannot [:role, :create, :destroy, :update], User, role: 'superadmin'
      can :update, User, id: user.id
      can :manage, UpDownload
      can :manage, Package
      can :manage, Order
      can :manage, AuthenticPicture
      #can :manage, User
    elsif user.unitadmin?
      can :manage, Unit, id: user.unit.id
      can :user, Unit, id: user.unit.id
      can :manage, Unit, parent_id: user.unit.id
      can :read, Unit        
      cannot :destroy, Unit, id: user.unit.id

      can :read, UserLog, user: {unit_id: user.unit_id}

      can :manage, User, unit_id: user.unit_id
      can :manage, User, unit_id: user.unit.child_unit_ids
      cannot [:role, :create, :destroy, :update], User, role: ['unitadmin', 'superadmin']
      can :update, User, id: user.id
      can :role, :user
      
      can :manage, UpDownload
      can :manage, Package, unit_id: user.unit_id.to_s
      cannot :scan, Package if user.unit.no == I18n.t('unit_no.gy')
      cannot [:gy_scan, :sorting_code_report, :package_report], Package if user.unit.no == I18n.t('unit_no.sy')
      can :manage, Order, unit_id: user.unit_id.to_s
      cannot [:other_province_index, :order_report, :order_report_export, :cancel], Order if user.unit.no.eql?(I18n.t('unit_no.sy'))
      can :authentic_pictures_report, AuthenticPicture if user.unit.no == I18n.t('unit_no.sy')
    else
      can :update, User, id: user.id
      can :read, UserLog, user: {id: user.id}
      can :read, Unit, id: user.unit_id
      can [:read, :up_download_export], UpDownload
      can :manage, Package, user_id: user.id
      cannot [:cancelled, :send_sy, :send_finish], Package
      cannot :scan, Package if user.unit.no == I18n.t('unit_no.gy')
      cannot [:gy_scan, :sorting_code_report, :package_report], Package if user.unit.no == I18n.t('unit_no.sy')
      can [:read, :order_report, :order_report_export], Order, unit_id: user.unit_id.to_s
      cannot [:order_report, :order_report_export, :cancel], Order if user.unit.no.eql?(I18n.t('unit_no.sy'))
      can :authentic_pictures_report, AuthenticPicture if user.unit.no == I18n.t('unit_no.sy')
    end

    

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
