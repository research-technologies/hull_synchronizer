module DataCrosswalks
  class MapCSV
    require 'csv'

    def initialize(data_mapper)
      @data_mapper = data_mapper
      output_file_dir = 'tmp'
      output_file_name = "#{Time.now.strftime('%Y-%m-%d_%H-%M-%S-%L')}.csv"
      @output_file_path = File.join(output_file_dir, output_file_name)
      @rows = 1
    end

    def generate_file
      if @data_mapper.original_file.exists?
        @data_mapper.status = 'Processing'
        @data_mapper.save!
        begin
          ::CSV.open(@output_file_path, 'wb') do |output_csv|
            # Write the headers
            output_csv << header.values
            # read each row
            ::CSV.foreach(@data_mapper.original_file.path, headers: true).each do |row|
              # process it
              new_row = deep_copy(row)
              to_process.each do |attr, func|
                new_row[attr] = self.send(func.to_sym, row)
              end
              # write each row
              output_csv << header.keys.map{ |attr| new_row.fetch(attr, nil) }
              @rows = @rows + 1
              @data_mapper.rows_processed = @rows
              @data_mapper.save!
            end
          end
        rescue Exception => e
          @data_mapper.rows_processed = @rows
          @data_mapper.status = 'Error'
          @data_mapper.message = e.message # e.backtrace.inspect
        else
          @data_mapper.rows_processed = @rows
          @data_mapper.status = 'Done'
        ensure
          @data_mapper.mapped_file = File.open(@output_file_path, 'rb')
          @data_mapper.save!
          @output_file.unlink
        end
      end
    end

    def deep_copy(o)
      Marshal.load(Marshal.dump(o))
    end

  end
end
