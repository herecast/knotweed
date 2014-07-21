class PromotionsController < ApplicationController
  # GET /promotions
  # GET /promotions.json
  def index
    @publication = Publication.find(params[:publication_id])
    @promotions = @publication.promotions

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @promotions }
    end
  end

  # GET /promotions/1
  # GET /promotions/1.json
  def show
    @promotion = Promotion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @promotion }
    end
  end

  # GET /promotions/new
  # GET /promotions/new.json
  def new
    publication = Publication.find(params[:publication_id])
    content = Content.find(params[:content_id]) unless params[:content_id].nil?
    @promotion = Promotion.new publication: publication
    @promotion.content = content unless content.nil?

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @promotion }
    end
  end

  # GET /promotions/1/edit
  def edit
    @promotion = Promotion.find(params[:id])
  end

  # POST /promotions
  # POST /promotions.json
  def create
    @promotion = Promotion.new(params[:promotion])
    pub = Publication.find params[:publication_id]
    @promotion.publication = pub

    respond_to do |format|
      if @promotion.save
        format.html { redirect_to @promotion, notice: 'Promotion was successfully created.' }
        format.json { render json: @promotion, status: :created, location: @promotion }
      else
        format.html { redirect_to edit_publication_path(pub), error: @promotion.errors.messages }
        format.json { render json: @promotion.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /promotions/1
  # PUT /promotions/1.json
  def update
    @promotion = Promotion.find(params[:id])

    respond_to do |format|
      if @promotion.update_attributes(params[:promotion])
        format.html { redirect_to @promotion, notice: 'Promotion was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @promotion.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /promotions/1
  # DELETE /promotions/1.json
  def destroy
    @promotion = Promotion.find(params[:id])
    pub = @promotion.publication
    @promotion.destroy

    respond_to do |format|
      format.html { redirect_to publication_promotions_path(pub), notice: 'Promotion successfully destroyed!' }
      format.json { head :no_content }
    end
  end
end
