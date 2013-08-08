#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class JournalManager

  def self.recreate_initial_journal(type, journal, changed_data)
    journal.changed_data = changed_data

    journal.save!
    journal.reload
  end

  def self.write_journal(journaled, user = User.current, notes = "")
    journal_attributes = { journaled_id: journaled.id,
                           journaled_type: journal_class_name(journaled.class),
                           version: (journaled.journals.count + 1),
                           activity_type: journaled.activity_type,
                           changed_data: journaled.attributes.symbolize_keys }

    create_journal base_class(journaled.class), journal_attributes, user, notes
  end

  def self.create_journal(type, journal_attributes, user = User.current,  notes = "")
    extended_journal_attributes = journal_attributes.merge({ journaled_type: journal_class_name(type) })
                                                    .merge({ notes: (notes.empty?) ? nil? : notes })
                                                    .except(:changed_data)
                                                    .except(:id)

    unless extended_journal_attributes.has_key? :user_id
      extended_journal_attributes[:user_id] = user.id
    end

    journal = create_journal_base extended_journal_attributes
    create_journal_data journal.id, type, journal_attributes[:changed_data].except(:id)

    journal
  end

  def self.create_journal_base(journal_attributes)
    Journal.create journal_attributes
  end

  def self.create_journal_data(journal_id, type, changed_data)
    journal_class = journal_class type
    new_data = Hash[changed_data.map{|k,v| [k, (v.kind_of? Array) ? v.last : v]}]

    new_data[:journal_id] = journal_id

    journal_class.create new_data
  end

  private

  def self.journal_class(type)
    "Journal::#{journal_class_name(type)}".constantize
  end

  def self.journal_class_name(type)
    "#{base_class(type).name}Journal"
  end

  def self.base_class(type)
    supertype = type.ancestors.find{|a| a != type and a.is_a? Class}

    supertype = type if supertype == ActiveRecord::Base

    supertype
  end

end
