class UpDownloadsController < ApplicationController
  load_and_authorize_resource

  def index
    @up_downloads = initialize_grid(@up_downloads, order: 'created_at',order_direction: :desc)
     #@up_download = UpDownload.all
  end

  def show
    
  end

  def new
    #@up_download = UpDownload.new
    #respond_with(@up_download)
  end

  def edit
  end

  def create
    respond_to do |format|
      unless request.get?
        if ! params[:file].blank? && ! params[:file]['file'].blank?
          file  = params[:file]['file']
          @up_download = UpDownload.new(up_download_params)
          file_path = UpDownload.upload(file)       
      
          @up_download.url = file_path
          @up_download.oper_date = Time.now
          
          # redirect_to up_downloads_url
        end
      end
      if @up_download.save
        UpDownload.write(file, file_path)
        flash[:alert] = "上传成功"
        format.html { redirect_to up_downloads_url, notice: I18n.t('controller.create_success_notice', model: '模板') }
        format.json { render action: 'show', status: :created, location: @up_download}
      else
        format.html { render action: 'up_download_import' }
        format.json { render json: @up_download.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    #@up_download.update(up_download_params)
    #respond_with(@up_download)
  end

  def destroy
    #@up_download.destroy
    #respond_with(@up_download)
    file_path = @up_download.url
    if File.exist?(file_path)
      File.delete(file_path)

      @up_download.destroy
    end
    respond_to do |format|
      format.html { redirect_to up_downloads_url }
      format.json { head :no_content }
    end
    
  end

  def to_import
    #redirect_to up_download_import_up_downloads_url
    @up_download = UpDownload.new
    render(:action => 'up_download_import')

  end

  
  def up_download_export
    up_download=UpDownload.find(params[:id])
    
    if up_download.nil?
       flash[:alert] = "无此文档模板"
       redirect_to :action => 'index'
    else
      file_path = up_download.url
      if File.exist?(file_path)
        io = File.open(file_path)
        # send_data(io.read,:filename => @up_download.name,:type => "text/excel;charset=utf-8; header=present", disposition: 'attachment')
        # send_data(io.read,:filename => filename,:type => "application/octet-stream", disposition: 'attachment')
        send_data(io.read,:filename => up_download.filename,:type => "text/excel;charset=utf-8; header=present", disposition: 'attachment')
        io.close
      else
        redirect_to up_downloads_path, :notice => '模板不存在，下载失败！'
      end
    end
  end

  private
    def set_up_download
      @up_download = UpDownload.find(params[:id])
    end

    def up_download_params
      params.require(:up_download).permit(:name, :use, :desc, :ver_no)
      
    end
end