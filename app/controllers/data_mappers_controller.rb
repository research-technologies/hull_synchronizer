class DataMappersController < ApplicationController
  def index
    @data_mappers = DataMapper.order('created_at')
  end

  # New action for creating a new data mapper record
  def new
    @data_mapper = DataMapper.new
  end

  def create
    @data_mapper = DataMapper.new(data_mapper_params)
    if @data_mapper.save
      @data_mapper.rows = `wc -l "#{@data_mapper.original_file.path}"`.strip.split(' ')[0].to_i
      @data_mapper.rows_processed = 0
      @data_mapper.status = 'Waiting'
      @data_mapper.save!
      CsvCrosswalkJob.perform_later(@data_mapper.id, @data_mapper.file_type)
      flash[:notice] = "Successfully uploaded csv file. the file is being processed.
        You can download the reformatted file once complete"
      redirect_to @data_mapper
    else
      flash[:alert] = "Error uploading csv file!"
      render :new
    end
  end

  def show
    @data_mapper = DataMapper.find(params[:id])
  end

  #Destroy action for deleting an already uploaded file
  def destroy
    @data_mapper = DataMapper.find(params[:id])
    if @data_mapper.destroy
      flash[:notice] = "Successfully deleted csv record!"
      redirect_to action: "index"
    else
      flash[:alert] = "Error deleting csv record"
    end
  end

  private

  #Permitted parameters when uploading a file. This is used for security reasons.
  def data_mapper_params
    params.require(:data_mapper).permit(:title, :file_type, :original_file)
  end

end
