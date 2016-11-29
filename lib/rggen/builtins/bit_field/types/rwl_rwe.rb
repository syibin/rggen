list_item :bit_field, :type, [:rwl, :rwe] do
  register_map do
    read_write
    need_initial_value
    use_reference width: 1, required: true
  end

  rtl do
    build do
      output :value_out,
             name:      "o_#{bit_field.name}",
             width:      width,
             dimensions: dimensions
    end

    generate_code :module_item do |code|
      code << assign(value_out[loop_variables], value[loop_variables]) << nl
      code << process_template
    end

    def lock_mode
      { rwl: 1, rwe: 0 }[bit_field.type]
    end

    def initial_value
      hex(bit_field.initial_value, width)
    end

    def lock_or_enable
      mode_field.value
    end

    def mode_field
      register_block.bit_fields.find_by(name: bit_field.reference.name)
    end
  end

  ral do
    model_name { "#{class_name}#(#{mode_register}, #{mode_field})" }

    def class_name
      "rggen_ral_field_#{bit_field.type}"
    end

    def mode_register
      string(bit_field.reference.register.name)
    end

    def mode_field
      string(bit_field.reference.name)
    end
  end
end